USE school_database;

-- 1. Business question: Which students are in JSS1 A, and who is their form teacher?
-- Technique: JOIN the class to its form teacher; LEFT JOIN students so an empty class still appears.
SELECT
    c.class_name,
    CONCAT(ft.first_name, ' ', ft.last_name) AS form_teacher,
    s.admission_number,
    s.first_name,
    s.last_name
FROM classes AS c
JOIN teachers AS ft ON ft.id = c.form_teacher_id
LEFT JOIN students AS s ON s.class_id = c.id
WHERE c.class_name = 'JSS1 A'
ORDER BY s.last_name, s.first_name;

-- 2. Business question: What is each student's subject total and letter grade for the term?
-- Technique: Add CA and exam scores, then use CASE to map the total to an A-F grade.
SELECT
    s.admission_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.class_name,
    sub.subject_name,
    r.ca_score,
    r.exam_score,
    r.ca_score + r.exam_score AS total_score,
    CASE
        WHEN r.ca_score + r.exam_score >= 80 THEN 'A'
        WHEN r.ca_score + r.exam_score >= 70 THEN 'B'
        WHEN r.ca_score + r.exam_score >= 60 THEN 'C'
        WHEN r.ca_score + r.exam_score >= 50 THEN 'D'
        WHEN r.ca_score + r.exam_score >= 40 THEN 'E'
        ELSE 'F'
    END AS grade
FROM results AS r
JOIN students AS s ON s.id = r.student_id
JOIN classes AS c ON c.id = r.class_id
JOIN subjects AS sub ON sub.id = r.subject_id
JOIN academic_terms AS term ON term.id = r.term_id
WHERE term.term_name = 'First Term'
  AND term.academic_year = '2026/2027'
ORDER BY c.class_name, s.last_name, s.first_name, sub.subject_name;

-- 3. Business question: What is each student's average and rank within their class for the term?
-- Technique: Aggregate one average per student, then use RANK() partitioned by class; ties share a rank.
WITH student_averages AS (
    SELECT
        s.id AS student_id,
        s.admission_number,
        s.first_name,
        s.last_name,
        c.id AS class_id,
        c.class_name,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM students AS s
    JOIN classes AS c ON c.id = s.class_id
    JOIN results AS r ON r.student_id = s.id
    JOIN academic_terms AS term ON term.id = r.term_id
    WHERE term.term_name = 'First Term'
      AND term.academic_year = '2026/2027'
    GROUP BY s.id, s.admission_number, s.first_name, s.last_name, c.id, c.class_name
)
SELECT
    admission_number,
    CONCAT(first_name, ' ', last_name) AS student_name,
    class_name,
    ROUND(average_score, 2) AS average_score,
    RANK() OVER (PARTITION BY class_id ORDER BY average_score DESC) AS class_position
FROM student_averages
ORDER BY class_name, class_position, student_name;

-- 3 (fallback for MySQL versions without window functions).
-- Technique: Aggregate student averages twice and count classmates with a strictly higher average.
SELECT
    scores.admission_number,
    scores.student_name,
    scores.class_name,
    ROUND(scores.average_score, 2) AS average_score,
    1 + COUNT(better.student_id) AS class_position
FROM (
    SELECT
        s.id AS student_id,
        s.admission_number,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        c.id AS class_id,
        c.class_name,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM students AS s
    JOIN classes AS c ON c.id = s.class_id
    JOIN results AS r ON r.student_id = s.id
    JOIN academic_terms AS term ON term.id = r.term_id
    WHERE term.term_name = 'First Term'
      AND term.academic_year = '2026/2027'
    GROUP BY s.id, s.admission_number, s.first_name, s.last_name, c.id, c.class_name
) AS scores
LEFT JOIN (
    SELECT
        s.id AS student_id,
        c.id AS class_id,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM students AS s
    JOIN classes AS c ON c.id = s.class_id
    JOIN results AS r ON r.student_id = s.id
    JOIN academic_terms AS term ON term.id = r.term_id
    WHERE term.term_name = 'First Term'
      AND term.academic_year = '2026/2027'
    GROUP BY s.id, c.id
) AS better
    ON better.class_id = scores.class_id
   AND better.average_score > scores.average_score
GROUP BY
    scores.student_id, scores.admission_number, scores.student_name,
    scores.class_id, scores.class_name, scores.average_score
ORDER BY scores.class_name, class_position, scores.student_name;

-- 4. Business question: What are the average, highest, and lowest subject scores in each class?
-- Technique: GROUP BY class, subject, and term; aggregate each student's CA-plus-exam total.
SELECT
    c.class_name,
    sub.subject_name,
    term.term_name,
    term.academic_year,
    ROUND(AVG(r.ca_score + r.exam_score), 2) AS average_score,
    MAX(r.ca_score + r.exam_score) AS highest_score,
    MIN(r.ca_score + r.exam_score) AS lowest_score
FROM results AS r
JOIN classes AS c ON c.id = r.class_id
JOIN subjects AS sub ON sub.id = r.subject_id
JOIN academic_terms AS term ON term.id = r.term_id
WHERE term.term_name = 'First Term'
  AND term.academic_year = '2026/2027'
GROUP BY c.id, c.class_name, sub.id, sub.subject_name, term.id, term.term_name, term.academic_year
ORDER BY c.class_name, sub.subject_name;

-- 5. Business question: Which students scored below 40 in at least two subjects this term?
-- Technique: GROUP BY student and use HAVING to count failing subject results.
SELECT
    s.admission_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.class_name,
    SUM(CASE WHEN r.ca_score + r.exam_score < 40 THEN 1 ELSE 0 END) AS failed_subjects
FROM results AS r
JOIN students AS s ON s.id = r.student_id
JOIN classes AS c ON c.id = r.class_id
JOIN academic_terms AS term ON term.id = r.term_id
WHERE term.term_name = 'First Term'
  AND term.academic_year = '2026/2027'
GROUP BY s.id, s.admission_number, s.first_name, s.last_name, c.id, c.class_name
HAVING SUM(CASE WHEN r.ca_score + r.exam_score < 40 THEN 1 ELSE 0 END) >= 2
ORDER BY c.class_name, student_name;

-- 6. Business question: How many subjects and classes does each teacher teach?
-- Technique: LEFT JOIN from teachers keeps teachers with no assignments; DISTINCT avoids duplicate counts.
SELECT
    t.staff_number,
    CONCAT(t.first_name, ' ', t.last_name) AS teacher_name,
    COUNT(DISTINCT cs.subject_id) AS subjects_taught,
    COUNT(DISTINCT cs.class_id) AS classes_taught
FROM teachers AS t
LEFT JOIN class_subjects AS cs ON cs.teacher_id = t.id
GROUP BY t.id, t.staff_number, t.first_name, t.last_name
ORDER BY teacher_name;

-- 7. Business question: Which students have attendance below 80%?
-- Technique: LEFT JOIN and GROUP BY include students with no records; excused days are excluded from the denominator.
-- Present and Late count as attended; students with no countable days receive 0%.
SELECT
    s.admission_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.class_name,
    COUNT(a.id) AS recorded_days,
    COALESCE(
        ROUND(
            100.0 * SUM(CASE WHEN a.status IN ('Present', 'Late') THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN a.id IS NOT NULL AND a.status <> 'Excused' THEN 1 ELSE 0 END), 0),
            2
        ),
        0
    ) AS attendance_percentage
FROM students AS s
JOIN classes AS c ON c.id = s.class_id
LEFT JOIN attendance AS a ON a.student_id = s.id
GROUP BY s.id, s.admission_number, s.first_name, s.last_name, c.id, c.class_name
HAVING attendance_percentage < 80
ORDER BY c.class_name, attendance_percentage, student_name;

-- 8. Business question: Who is the top student in each class for the term?
-- Technique: Rank class averages with a window function; RANK returns every student tied for first.
WITH student_averages AS (
    SELECT
        s.id AS student_id,
        s.admission_number,
        s.first_name,
        s.last_name,
        c.id AS class_id,
        c.class_name,
        AVG(r.ca_score + r.exam_score) AS average_score
    FROM students AS s
    JOIN classes AS c ON c.id = s.class_id
    JOIN results AS r ON r.student_id = s.id
    JOIN academic_terms AS term ON term.id = r.term_id
    WHERE term.term_name = 'First Term'
      AND term.academic_year = '2026/2027'
    GROUP BY s.id, s.admission_number, s.first_name, s.last_name, c.id, c.class_name
),
ranked_students AS (
    SELECT
        student_averages.*,
        RANK() OVER (PARTITION BY class_id ORDER BY average_score DESC) AS class_position
    FROM student_averages
)
SELECT
    class_name,
    admission_number,
    CONCAT(first_name, ' ', last_name) AS student_name,
    ROUND(average_score, 2) AS average_score
FROM ranked_students
WHERE class_position = 1
ORDER BY class_name, student_name;

-- View: One row per student, subject, and term, with scores and the A-F grade.
CREATE OR REPLACE VIEW v_student_results AS
SELECT
    s.id AS student_id,
    s.admission_number,
    s.first_name,
    s.last_name,
    c.class_name,
    sub.subject_code,
    sub.subject_name,
    term.term_name,
    term.academic_year,
    r.ca_score,
    r.exam_score,
    r.total_score,
    CASE
        WHEN r.total_score >= 80 THEN 'A'
        WHEN r.total_score >= 70 THEN 'B'
        WHEN r.total_score >= 60 THEN 'C'
        WHEN r.total_score >= 50 THEN 'D'
        WHEN r.total_score >= 40 THEN 'E'
        ELSE 'F'
    END AS grade
FROM results AS r
JOIN students AS s ON s.id = r.student_id
JOIN classes AS c ON c.id = r.class_id
JOIN subjects AS sub ON sub.id = r.subject_id
JOIN academic_terms AS term ON term.id = r.term_id;

-- View: One row per class and term, including classes with no students or results.
CREATE OR REPLACE VIEW v_class_summary AS
SELECT
    c.id AS class_id,
    c.class_name,
    term.id AS term_id,
    term.term_name,
    term.academic_year,
    COUNT(DISTINCT s.id) AS student_count,
    COUNT(r.id) AS result_count,
    ROUND(AVG(r.total_score), 2) AS average_score,
    MAX(r.total_score) AS highest_score,
    MIN(r.total_score) AS lowest_score
FROM classes AS c
CROSS JOIN academic_terms AS term
LEFT JOIN students AS s ON s.class_id = c.id
LEFT JOIN results AS r
    ON r.student_id = s.id
   AND r.class_id = c.id
   AND r.term_id = term.id
GROUP BY c.id, c.class_name, term.id, term.term_name, term.academic_year;
