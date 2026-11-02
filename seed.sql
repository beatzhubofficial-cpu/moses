USE school_database;

SET NAMES utf8mb4;

INSERT INTO classes (class_name, level) VALUES
    ('JSS 1 A', 'JSS 1'),
    ('JSS 2 A', 'JSS 2'),
    ('SS 1 A', 'SS 1');

INSERT INTO teachers (staff_number, first_name, last_name, email, phone) VALUES
    ('STF001', 'Adaeze', 'Okafor', 'adaeze.okafor@mosesschool.edu.ng', '08031234001'),
    ('STF002', 'Chinedu', 'Eze', 'chinedu.eze@mosesschool.edu.ng', '08031234002'),
    ('STF003', 'Fatima', 'Bello', 'fatima.bello@mosesschool.edu.ng', '08031234003'),
    ('STF004', 'Tunde', 'Adeyemi', 'tunde.adeyemi@mosesschool.edu.ng', '08031234004'),
    ('STF005', 'Ngozi', 'Nwosu', 'ngozi.nwosu@mosesschool.edu.ng', '08031234005'),
    ('STF006', 'Ibrahim', 'Yusuf', 'ibrahim.yusuf@mosesschool.edu.ng', '08031234006');

INSERT INTO subjects (subject_code, subject_name) VALUES
    ('ENG', 'English Language'),
    ('MTH', 'Mathematics'),
    ('BST', 'Basic Science and Technology'),
    ('SST', 'Social Studies'),
    ('CVE', 'Civic Education'),
    ('CST', 'Computer Studies'),
    ('AGR', 'Agricultural Science'),
    ('BUS', 'Business Studies');

INSERT INTO academic_terms (term_name, academic_year, start_date, end_date) VALUES
    ('First Term', '2026/2027', '2026-09-14', '2026-12-18');

INSERT INTO class_subjects (class_id, subject_id, teacher_id)
SELECT c.id, s.id,
       t.id
FROM classes AS c
CROSS JOIN subjects AS s
JOIN teachers AS t
    ON t.staff_number = CASE s.subject_code
        WHEN 'ENG' THEN 'STF001'
        WHEN 'MTH' THEN 'STF002'
        WHEN 'BST' THEN 'STF003'
        WHEN 'SST' THEN 'STF004'
        WHEN 'CVE' THEN 'STF004'
        WHEN 'CST' THEN 'STF005'
        WHEN 'AGR' THEN 'STF006'
        WHEN 'BUS' THEN 'STF005'
    END;

INSERT INTO students (
    admission_number, first_name, last_name, gender, date_of_birth,
    guardian_name, guardian_phone, date_admitted, class_id
)
SELECT student_seed.admission_number, student_seed.first_name, student_seed.last_name,
       student_seed.gender, student_seed.date_of_birth, student_seed.guardian_name,
       student_seed.guardian_phone, '2026-09-01', c.id
FROM (
    SELECT 'MOS/2026/001' AS admission_number, 'Amara' AS first_name, 'Okafor' AS last_name, 'Female' AS gender, '2013-04-12' AS date_of_birth, 'Emeka Okafor' AS guardian_name, '08041110001' AS guardian_phone, 'JSS 1 A' AS class_name
    UNION ALL SELECT 'MOS/2026/002', 'Chukwuemeka', 'Obi', 'Male', '2013-08-03', 'Ngozi Obi', '08041110002', 'JSS 1 A'
    UNION ALL SELECT 'MOS/2026/003', 'Zainab', 'Abdullahi', 'Female', '2013-01-21', 'Musa Abdullahi', '08041110003', 'JSS 1 A'
    UNION ALL SELECT 'MOS/2026/004', 'Tobi', 'Adeyemi', 'Male', '2013-11-09', 'Kemi Adeyemi', '08041110004', 'JSS 1 A'
    UNION ALL SELECT 'MOS/2026/005', 'Ifeoma', 'Nwankwo', 'Female', '2013-06-17', 'Chika Nwankwo', '08041110005', 'JSS 1 A'
    UNION ALL SELECT 'MOS/2026/006', 'Seyi', 'Adeleke', 'Male', '2013-02-26', 'Bola Adeleke', '08041110006', 'JSS 1 A'
    UNION ALL SELECT 'MOS/2026/007', 'Hauwa', 'Sani', 'Female', '2013-09-14', 'Bashir Sani', '08041110007', 'JSS 1 A'
    UNION ALL SELECT 'MOS/2026/008', 'Chidera', 'Eze', 'Male', '2013-05-30', 'Ijeoma Eze', '08041110008', 'JSS 1 A'
    UNION ALL SELECT 'MOS/2026/009', 'Yetunde', 'Bakare', 'Female', '2013-12-06', 'Akin Bakare', '08041110009', 'JSS 1 A'
    UNION ALL SELECT 'MOS/2026/010', 'Musa', 'Garba', 'Male', '2013-03-19', 'Aisha Garba', '08041110010', 'JSS 1 A'
    UNION ALL SELECT 'MOS/2026/011', 'Kelechi', 'Eze', 'Male', '2012-07-08', 'Uche Eze', '08041110011', 'JSS 2 A'
    UNION ALL SELECT 'MOS/2026/012', 'Aisha', 'Mohammed', 'Female', '2012-10-25', 'Yusuf Mohammed', '08041110012', 'JSS 2 A'
    UNION ALL SELECT 'MOS/2026/013', 'Oluwaseun', 'Ojo', 'Male', '2012-02-14', 'Funmi Ojo', '08041110013', 'JSS 2 A'
    UNION ALL SELECT 'MOS/2026/014', 'Nneka', 'Ezeani', 'Female', '2012-05-03', 'Ikenna Ezeani', '08041110014', 'JSS 2 A'
    UNION ALL SELECT 'MOS/2026/015', 'Abubakar', 'Ibrahim', 'Male', '2012-12-11', 'Rukayya Ibrahim', '08041110015', 'JSS 2 A'
    UNION ALL SELECT 'MOS/2026/016', 'Temiloluwa', 'Akinola', 'Female', '2012-08-29', 'Femi Akinola', '08041110016', 'JSS 2 A'
    UNION ALL SELECT 'MOS/2026/017', 'Chisom', 'Umeh', 'Female', '2012-04-07', 'Obinna Umeh', '08041110017', 'JSS 2 A'
    UNION ALL SELECT 'MOS/2026/018', 'Babatunde', 'Lawal', 'Male', '2012-09-16', 'Mariam Lawal', '08041110018', 'JSS 2 A'
    UNION ALL SELECT 'MOS/2026/019', 'Maryam', 'Usman', 'Female', '2012-01-31', 'Sule Usman', '08041110019', 'JSS 2 A'
    UNION ALL SELECT 'MOS/2026/020', 'Obinna', 'Anyanwu', 'Male', '2012-06-22', 'Chinyere Anyanwu', '08041110020', 'JSS 2 A'
    UNION ALL SELECT 'MOS/2026/021', 'Oluwatobi', 'Ogunleye', 'Male', '2011-03-05', 'Sola Ogunleye', '08041110021', 'SS 1 A'
    UNION ALL SELECT 'MOS/2026/022', 'Chiamaka', 'Okeke', 'Female', '2011-11-18', 'Ifeanyi Okeke', '08041110022', 'SS 1 A'
    UNION ALL SELECT 'MOS/2026/023', 'Fatima', 'Abubakar', 'Female', '2011-07-27', 'Salihu Abubakar', '08041110023', 'SS 1 A'
    UNION ALL SELECT 'MOS/2026/024', 'Damilola', 'Afolabi', 'Male', '2011-01-13', 'Titi Afolabi', '08041110024', 'SS 1 A'
    UNION ALL SELECT 'MOS/2026/025', 'Ebere', 'Madu', 'Female', '2011-09-02', 'Chukwudi Madu', '08041110025', 'SS 1 A'
    UNION ALL SELECT 'MOS/2026/026', 'Yusuf', 'Lawal', 'Male', '2011-05-16', 'Amina Lawal', '08041110026', 'SS 1 A'
    UNION ALL SELECT 'MOS/2026/027', 'Bisola', 'Alabi', 'Female', '2011-12-20', 'Tunde Alabi', '08041110027', 'SS 1 A'
    UNION ALL SELECT 'MOS/2026/028', 'Chukwuebuka', 'Nnamdi', 'Male', '2011-04-09', 'Ngozi Nnamdi', '08041110028', 'SS 1 A'
    UNION ALL SELECT 'MOS/2026/029', 'Hadiza', 'Musa', 'Female', '2011-08-11', 'Ibrahim Musa', '08041110029', 'SS 1 A'
    UNION ALL SELECT 'MOS/2026/030', 'Olamide', 'Fashola', 'Male', '2011-02-24', 'Bisi Fashola', '08041110030', 'SS 1 A'
) AS student_seed
JOIN classes AS c ON c.class_name = student_seed.class_name;

INSERT INTO results (student_id, class_id, subject_id, term_id, ca_score, exam_score, remarks)
SELECT s.id, s.class_id, cs.subject_id, term.id,
       MOD(s.id * 7 + cs.subject_id * 11, 40) + 1,
       MOD(s.id * 13 + cs.subject_id * 17, 60) + 1,
       'Sample result'
FROM students AS s
JOIN class_subjects AS cs ON cs.class_id = s.class_id
CROSS JOIN academic_terms AS term
WHERE term.term_name = 'First Term'
  AND term.academic_year = '2026/2027';

INSERT INTO attendance (student_id, attendance_date, status)
SELECT s.id, school_days.attendance_date,
       CASE MOD(s.id + school_days.day_number, 23)
           WHEN 0 THEN 'Absent'
           WHEN 1 THEN 'Late'
           WHEN 2 THEN 'Excused'
           ELSE 'Present'
       END
FROM students AS s
CROSS JOIN (
    SELECT 0 AS day_number, DATE('2026-09-14') AS attendance_date
    UNION ALL SELECT 1, DATE('2026-09-15')
    UNION ALL SELECT 2, DATE('2026-09-16')
    UNION ALL SELECT 3, DATE('2026-09-17')
    UNION ALL SELECT 4, DATE('2026-09-18')
) AS school_days;
