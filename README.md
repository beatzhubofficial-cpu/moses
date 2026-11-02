# School Database Project

A lightweight SQLite-based school database for tracking students, courses, teachers, enrollments, and attendance.

## Features

- Manage students and their grade levels
- Track teachers and course assignments
- Record enrollments and final grades
- Monitor attendance percentages
- Run simple reports from the command line

## Getting started

1. Open a terminal in this project folder.
2. Run the database initializer:

   python main.py init

3. Use the interactive menu:

   python main.py

4. Or run direct commands:

   python main.py list-students
   python main.py list-courses
   python main.py student-report --student-id 1
   python main.py course-roster --course-id 1

## File overview

- `main.py` – CLI app and database logic
- `schema.sql` – SQLite schema definitions
- `school.db` – local database file created after initialization

## Notes

The app seeds sample data automatically when the database is first created, so you can immediately test reports and roster queries.
