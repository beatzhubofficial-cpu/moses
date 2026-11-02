import argparse
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent / "school.db"
SCHEMA_PATH = Path(__file__).resolve().parent / "schema.sql"


def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with SCHEMA_PATH.open("r", encoding="utf-8") as schema_file:
        schema_sql = schema_file.read()
    conn = get_connection()
    try:
        conn.executescript(schema_sql)
        seed_if_needed(conn)
        conn.commit()
        print(f"Database initialized at {DB_PATH}")
    finally:
        conn.close()


def seed_if_needed(conn):
    if conn.execute("SELECT COUNT(*) FROM students").fetchone()[0] > 0:
        return

    teachers = [
        ("Maya", "Roberts", "maya.roberts@school.edu", "Mathematics"),
        ("Daniel", "Nguyen", "daniel.nguyen@school.edu", "Science"),
        ("Alicia", "Patel", "alicia.patel@school.edu", "English")
    ]
    conn.executemany(
        "INSERT INTO teachers (first_name, last_name, email, department) VALUES (?, ?, ?, ?)",
        teachers,
    )

    courses = [
        ("MATH101", "Algebra I", 1, 1),
        ("BIO205", "Biology", 1, 2),
        ("ENG110", "English Literature", 1, 3),
    ]
    conn.executemany(
        "INSERT INTO courses (course_code, title, credits, teacher_id) VALUES (?, ?, ?, ?)",
        courses,
    )

    students = [
        ("Emma", "Johnson", "2009-05-11", "emma.johnson@school.edu", 9),
        ("Lucas", "Martinez", "2008-12-05", "lucas.martinez@school.edu", 10),
        ("Ava", "Brown", "2010-02-17", "ava.brown@school.edu", 8),
        ("Noah", "Taylor", "2007-09-22", "noah.taylor@school.edu", 11),
    ]
    conn.executemany(
        "INSERT INTO students (first_name, last_name, date_of_birth, email, grade_level) VALUES (?, ?, ?, ?, ?)",
        students,
    )

    enrollments = [
        (1, 1, "Fall 2026", 92.0),
        (1, 3, "Fall 2026", 88.0),
        (2, 1, "Fall 2026", 85.0),
        (2, 2, "Fall 2026", 90.0),
        (3, 2, "Fall 2026", 78.0),
        (4, 3, "Fall 2026", 95.0),
    ]
    conn.executemany(
        "INSERT INTO enrollments (student_id, course_id, semester, final_grade) VALUES (?, ?, ?, ?)",
        enrollments,
    )

    attendance = [
        (1, 1, "2026-09-02", 1),
        (1, 3, "2026-09-02", 1),
        (2, 1, "2026-09-02", 0),
        (2, 2, "2026-09-02", 1),
        (3, 2, "2026-09-02", 1),
        (4, 3, "2026-09-02", 1),
    ]
    conn.executemany(
        "INSERT INTO attendance (student_id, course_id, date, present) VALUES (?, ?, ?, ?)",
        attendance,
    )


def list_students():
    conn = get_connection()
    rows = conn.execute(
        "SELECT id, first_name, last_name, grade_level, email FROM students ORDER BY last_name, first_name"
    ).fetchall()
    conn.close()
    if not rows:
        print("No students found.")
        return
    print("\nStudents:")
    for row in rows:
        print(f"{row['id']:>2} | {row['first_name']} {row['last_name']} | Grade {row['grade_level']} | {row['email']}")


def list_courses():
    conn = get_connection()
    rows = conn.execute(
        "SELECT c.id, c.course_code, c.title, t.first_name || ' ' || t.last_name AS teacher_name, c.credits "
        "FROM courses c LEFT JOIN teachers t ON t.id = c.teacher_id ORDER BY c.course_code"
    ).fetchall()
    conn.close()
    if not rows:
        print("No courses found.")
        return
    print("\nCourses:")
    for row in rows:
        print(f"{row['id']:>2} | {row['course_code']} | {row['title']} | {row['teacher_name'] or 'Unassigned'} | {row['credits']} credits")


def student_report(student_id):
    conn = get_connection()
    student = conn.execute(
        "SELECT first_name, last_name, grade_level FROM students WHERE id = ?",
        (student_id,),
    ).fetchone()
    if student is None:
        print(f"Student {student_id} was not found.")
        conn.close()
        return
 
    enrollments = conn.execute(
        "SELECT c.course_code, c.title, e.final_grade FROM enrollments e JOIN courses c ON c.id = e.course_id WHERE e.student_id = ? ORDER BY c.course_code",
        (student_id,),
    ).fetchall()
    attendance_total = conn.execute(
        "SELECT COUNT(*) AS total_days, SUM(present) AS present_days FROM attendance WHERE student_id = ?",
        (student_id,),
    ).fetchone()
    conn.close()

    print(f"\nStudent: {student['first_name']} {student['last_name']} (Grade {student['grade_level']})")
    if not enrollments:
        print("No course enrollments found.")
    else:
        print("Courses:")
        for row in enrollments:
            grade_text = row["final_grade"] if row["final_grade"] is not None else "N/A"
            print(f"- {row['course_code']}: {row['title']} | Final grade: {grade_text}")

    if attendance_total and attendance_total["total_days"]:
        pct = (attendance_total["present_days"] / attendance_total["total_days"]) * 100
        print(f"Attendance: {attendance_total['present_days']} / {attendance_total['total_days']} days ({pct:.1f}%)")


def course_roster(course_id):
    conn = get_connection()
    course = conn.execute(
        "SELECT course_code, title FROM courses WHERE id = ?",
        (course_id,),
    ).fetchone()
    if course is None:
        print(f"Course {course_id} was not found.")
        conn.close()
        return

    rows = conn.execute(
        "SELECT s.id, s.first_name, s.last_name, e.final_grade FROM enrollments e JOIN students s ON s.id = e.student_id WHERE e.course_id = ? ORDER BY s.last_name, s.first_name",
        (course_id,),
    ).fetchall()
    conn.close()
    print(f"\nCourse roster: {course['course_code']} - {course['title']}")
    if not rows:
        print("No students enrolled.")
        return
    for row in rows:
        grade = row["final_grade"] if row["final_grade"] is not None else "N/A"
        print(f"{row['id']:>2} | {row['first_name']} {row['last_name']} | Grade: {grade}")


def add_student(first_name, last_name, dob, email, grade_level):
    conn = get_connection()
    try:
        conn.execute(
            "INSERT INTO students (first_name, last_name, date_of_birth, email, grade_level) VALUES (?, ?, ?, ?, ?)",
            (first_name, last_name, dob, email, grade_level),
        )
        conn.commit()
        print(f"Added student: {first_name} {last_name}")
    except sqlite3.IntegrityError as exc:
        print(f"Unable to add student: {exc}")
    finally:
        conn.close()


def add_enrollment(student_id, course_id, semester, final_grade=None):
    conn = get_connection()
    try:
        conn.execute(
            "INSERT INTO enrollments (student_id, course_id, semester, final_grade) VALUES (?, ?, ?, ?)",
            (student_id, course_id, semester, final_grade),
        )
        conn.commit()
        print(f"Enrollment added for student {student_id} in course {course_id}.")
    except sqlite3.IntegrityError as exc:
        print(f"Unable to add enrollment: {exc}")
    finally:
        conn.close()


def interactive_menu():
    while True:
        print("\nSchool Database Manager")
        print("1. List students")
        print("2. List courses")
        print("3. Show student report")
        print("4. Show course roster")
        print("5. Add student")
        print("6. Add enrollment")
        print("0. Exit")
        choice = input("Select an option: ").strip()

        if choice == "1":
            list_students()
        elif choice == "2":
            list_courses()
        elif choice == "3":
            student_id = input("Student ID: ").strip()
            if student_id:
                student_report(int(student_id))
        elif choice == "4":
            course_id = input("Course ID: ").strip()
            if course_id:
                course_roster(int(course_id))
        elif choice == "5":
            first_name = input("First name: ").strip()
            last_name = input("Last name: ").strip()
            dob = input("Date of birth (YYYY-MM-DD): ").strip()
            email = input("Email: ").strip()
            grade_level = int(input("Grade level: ").strip())
            add_student(first_name, last_name, dob, email, grade_level)
        elif choice == "6":
            student_id = int(input("Student ID: ").strip())
            course_id = int(input("Course ID: ").strip())
            semester = input("Semester: ").strip()
            final_grade = input("Final grade (optional): ").strip() or None
            add_enrollment(student_id, course_id, semester, float(final_grade) if final_grade else None)
        elif choice == "0":
            print("Goodbye!")
            break
        else:
            print("Invalid option. Please try again.")


def parse_args():
    parser = argparse.ArgumentParser(description="School database management tool")
    parser.add_argument("command", nargs="?", choices=["init", "list-students", "list-courses", "student-report", "course-roster", "add-student", "add-enrollment", "menu"], default="menu")
    parser.add_argument("--student-id", type=int)
    parser.add_argument("--course-id", type=int)
    parser.add_argument("--first-name")
    parser.add_argument("--last-name")
    parser.add_argument("--dob")
    parser.add_argument("--email")
    parser.add_argument("--grade-level", type=int)
    parser.add_argument("--semester")
    parser.add_argument("--final-grade", type=float)
    return parser.parse_args()


def main():
    args = parse_args()
    if args.command == "init":
        init_db()
        return
    if args.command == "list-students":
        list_students()
        return
    if args.command == "list-courses":
        list_courses()
        return
    if args.command == "student-report":
        if args.student_id is None:
            raise SystemExit("student-report requires --student-id")
        student_report(args.student_id)
        return
    if args.command == "course-roster":
        if args.course_id is None:
            raise SystemExit("course-roster requires --course-id")
        course_roster(args.course_id)
        return
    if args.command == "add-student":
        if None in (args.first_name, args.last_name, args.dob, args.email, args.grade_level):
            raise SystemExit("add-student requires --first-name, --last-name, --dob, --email, and --grade-level")
        add_student(args.first_name, args.last_name, args.dob, args.email, args.grade_level)
        return
    if args.command == "add-enrollment":
        if None in (args.student_id, args.course_id, args.semester):
            raise SystemExit("add-enrollment requires --student-id, --course-id, and --semester")
        add_enrollment(args.student_id, args.course_id, args.semester, args.final_grade)
        return

    init_db()
    interactive_menu()


if __name__ == "__main__":
    main()
