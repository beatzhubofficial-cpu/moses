# School Database Project

A school database project with a MySQL/MariaDB schema and a separate SQLite command-line demo.

## Local web dashboard

The read-only browser dashboard uses the local `school.db` SQLite database and requires only Python 3.10+ (no package installation):

```text
python server.py
```

Open [http://127.0.0.1:8000](http://127.0.0.1:8000) in a browser. The server binds to localhost only, and the dashboard reflects the existing SQLite CLI data (students, teachers, courses, enrollments, and attendance); it does not display or modify the MySQL/MariaDB database. Stop it with Ctrl+C.

## MySQL/MariaDB database

`schema.sql` creates the `school_database` database and its InnoDB tables, including each class's form teacher. It drops and recreates the tables, so running it again deletes existing data. `seed.sql` adds Nigerian sample data: 3 classes, 8 subjects, 6 teachers, 30 students, one term, 240 results, and 150 attendance records over five days.

`queries.sql` contains the eight example reporting queries, a window-function fallback for older MySQL ranking, and the `v_student_results` and `v_class_summary` views. It uses the seeded `First Term` of `2026/2027`.

Use MySQL 8.0.16+ or MariaDB 10.2.1+ so the score and date `CHECK` constraints are enforced. From a MySQL/MariaDB client, run:

```sql
SOURCE schema.sql;
SOURCE seed.sql;
SOURCE queries.sql;
```

Or execute the files with the command-line client:

```text
mysql -u your_user -p < schema.sql
mysql -u your_user -p school_database < seed.sql
```

## SQLite command-line demo

The existing CLI uses `schema.sqlite.sql` and the local `school.db` file:

```text
python main.py init
python main.py
```

It also supports direct commands:

```text
python main.py list-students
python main.py list-courses
python main.py student-report --student-id 1
python main.py course-roster --course-id 1
```

## File overview

- `schema.sql` – MySQL/MariaDB InnoDB schema
- `seed.sql` – MySQL/MariaDB sample data
- `schema.sqlite.sql` – schema used by the SQLite CLI
- `main.py` – SQLite CLI app and database logic
- `school.db` – local SQLite database created after initialization
