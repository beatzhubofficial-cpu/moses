import json
import logging
import sqlite3
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit


ROOT = Path(__file__).resolve().parent
DATABASE_PATH = ROOT / "school.db"
INDEX_PATH = ROOT / "web" / "index.html"
ASSET_PATHS = {
    "/app.js": (ROOT / "web" / "app.js", "text/javascript; charset=utf-8"),
    "/styles.css": (ROOT / "web" / "styles.css", "text/css; charset=utf-8"),
}
HOST = "127.0.0.1"
PORT = 8000


def fetch_rows(connection, query, parameters=()):
    return [dict(row) for row in connection.execute(query, parameters).fetchall()]


def get_dashboard_data(connection, path):
    if path == "/api/overview":
        return {
            "students": connection.execute(
                "SELECT COUNT(*) FROM students"
            ).fetchone()[0],
            "teachers": connection.execute(
                "SELECT COUNT(*) FROM teachers"
            ).fetchone()[0],
            "courses": connection.execute(
                "SELECT COUNT(*) FROM courses"
            ).fetchone()[0],
            "enrollments": connection.execute(
                "SELECT COUNT(*) FROM enrollments"
            ).fetchone()[0],
            "attendance_rate": connection.execute(
                "SELECT ROUND(100.0 * COALESCE(SUM(present), 0) / NULLIF(COUNT(*), 0), 1) "
                "FROM attendance"
            ).fetchone()[0],
            "average_grade": connection.execute(
                "SELECT ROUND(AVG(final_grade), 1) FROM enrollments "
                "WHERE final_grade IS NOT NULL"
            ).fetchone()[0],
            "attendance_records": connection.execute(
                "SELECT COUNT(*) FROM attendance"
            ).fetchone()[0],
        }

    if path == "/api/students":
        return fetch_rows(
            connection,
            """
            SELECT s.id, s.first_name, s.last_name, s.grade_level, s.email,
                   s.enrollment_date,
                   COALESCE(e.course_count, 0) AS course_count,
                   e.average_grade,
                   COALESCE(a.attendance_days, 0) AS attendance_days,
                   a.attendance_rate
            FROM students AS s
            LEFT JOIN (
                SELECT student_id, COUNT(*) AS course_count,
                       ROUND(AVG(final_grade), 1) AS average_grade
                FROM enrollments
                GROUP BY student_id
            ) AS e ON e.student_id = s.id
            LEFT JOIN (
                SELECT student_id, COUNT(*) AS attendance_days,
                       ROUND(100.0 * SUM(present) / NULLIF(COUNT(*), 0), 1) AS attendance_rate
                FROM attendance
                GROUP BY student_id
            ) AS a ON a.student_id = s.id
            ORDER BY s.last_name, s.first_name
            """,
        )

    if path == "/api/courses":
        return fetch_rows(
            connection,
            """
            SELECT c.id, c.course_code, c.title, c.credits,
                   t.first_name AS teacher_first_name,
                   t.last_name AS teacher_last_name,
                   COUNT(DISTINCT e.student_id) AS student_count,
                   ROUND(AVG(e.final_grade), 1) AS average_grade
            FROM courses AS c
            LEFT JOIN teachers AS t ON t.id = c.teacher_id
            LEFT JOIN enrollments AS e ON e.course_id = c.id
            GROUP BY c.id, c.course_code, c.title, c.credits,
                     t.first_name, t.last_name
            ORDER BY c.course_code
            """,
        )

    if path == "/api/results":
        return fetch_rows(
            connection,
            """
            SELECT e.id, e.semester, e.final_grade,
                   s.first_name, s.last_name, s.grade_level,
                   c.course_code, c.title AS course_title
            FROM enrollments AS e
            JOIN students AS s ON s.id = e.student_id
            JOIN courses AS c ON c.id = e.course_id
            ORDER BY e.semester DESC, s.last_name, s.first_name, c.course_code
            """,
        )

    if path == "/api/attendance":
        return fetch_rows(
            connection,
            """
            SELECT a.id, a.date, a.present,
                   s.first_name, s.last_name, s.grade_level,
                   c.course_code, c.title AS course_title
            FROM attendance AS a
            JOIN students AS s ON s.id = a.student_id
            JOIN courses AS c ON c.id = a.course_id
            ORDER BY a.date DESC, s.last_name, s.first_name
            """,
        )

    return None


class DashboardHandler(BaseHTTPRequestHandler):
    server_version = "SchoolDashboard"

    def end_headers(self):
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header(
            "Content-Security-Policy",
            "default-src 'self'; script-src 'self'; style-src 'self'; "
            "connect-src 'self'; img-src 'self' data:; base-uri 'none'; "
            "frame-ancestors 'none'",
        )
        super().end_headers()

    def send_content(self, content, content_type, status=200):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(content)

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_content(body, "application/json; charset=utf-8", status)

    def do_GET(self):
        path = urlsplit(self.path).path
        if path == "/":
            try:
                body = INDEX_PATH.read_bytes()
            except OSError:
                logging.exception("Could not read the dashboard page")
                self.send_json({"error": "Could not read the dashboard page."}, 500)
                return
            self.send_content(body, "text/html; charset=utf-8")
            return

        if path in ASSET_PATHS:
            asset_path, content_type = ASSET_PATHS[path]
            try:
                body = asset_path.read_bytes()
            except OSError:
                logging.exception("Could not read dashboard asset %s", path)
                self.send_json({"error": "Could not read the dashboard asset."}, 500)
                return
            self.send_content(body, content_type)
            return

        if path == "/health":
            self.send_json({"status": "ok"})
            return

        if path.startswith("/api/"):
            try:
                with sqlite3.connect(
                    f"file:{DATABASE_PATH.as_posix()}?mode=ro", uri=True
                ) as connection:
                    connection.row_factory = sqlite3.Row
                    data = get_dashboard_data(connection, path)
            except sqlite3.Error:
                logging.exception("Database query failed for %s", path)
                self.send_json(
                    {"error": "Database query failed. Check the server terminal."},
                    500,
                )
                return
            if data is None:
                self.send_json({"error": "API endpoint not found."}, 404)
                return
            self.send_json(data)
            return

        self.send_json({"error": "Page not found."}, 404)

    def do_POST(self):
        self.send_json({"error": "This dashboard is read-only."}, 405)

    def log_message(self, format_string, *args):
        logging.info("%s - %s", self.address_string(), format_string % args)


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    server = ThreadingHTTPServer((HOST, PORT), DashboardHandler)
    server.daemon_threads = True
    print(f"School dashboard: http://{HOST}:{PORT}")
    print(f"Reading SQLite database: {DATABASE_PATH}")
    print("Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping school dashboard.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
