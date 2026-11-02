import sqlite3
import unittest
from pathlib import Path

import main
from server import get_dashboard_data


class DashboardDataTests(unittest.TestCase):
    def setUp(self):
        self.connection = sqlite3.connect(":memory:")
        self.connection.row_factory = sqlite3.Row
        self.connection.executescript(
            (Path(__file__).resolve().parents[1] / "schema.sqlite.sql").read_text(
                encoding="utf-8"
            )
        )
        main.seed_if_needed(self.connection)

    def tearDown(self):
        self.connection.close()

    def test_overview_summarizes_seeded_school_data(self):
        overview = get_dashboard_data(self.connection, "/api/overview")

        self.assertEqual(overview["students"], 4)
        self.assertEqual(overview["teachers"], 3)
        self.assertEqual(overview["courses"], 3)
        self.assertEqual(overview["enrollments"], 6)
        self.assertEqual(overview["attendance_rate"], 83.3)
        self.assertEqual(overview["average_grade"], 88.0)

    def test_all_read_views_return_seeded_records(self):
        self.assertEqual(len(get_dashboard_data(self.connection, "/api/students")), 4)
        self.assertEqual(len(get_dashboard_data(self.connection, "/api/courses")), 3)
        self.assertEqual(len(get_dashboard_data(self.connection, "/api/results")), 6)
        self.assertEqual(len(get_dashboard_data(self.connection, "/api/attendance")), 6)

    def test_unknown_api_route_is_not_silently_served(self):
        self.assertIsNone(get_dashboard_data(self.connection, "/api/missing"))


if __name__ == "__main__":
    unittest.main()
