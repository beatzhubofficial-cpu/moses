CREATE DATABASE IF NOT EXISTS school_database
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE school_database;

SET NAMES utf8mb4;

DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS class_subjects;
DROP TABLE IF EXISTS academic_terms;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS classes;
DROP TABLE IF EXISTS teachers;

CREATE TABLE classes (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    class_name VARCHAR(30) NOT NULL,
    level ENUM('JSS 1', 'JSS 2', 'SS 1') NOT NULL,
    form_teacher_id BIGINT UNSIGNED,
    PRIMARY KEY (id),
    UNIQUE KEY uq_classes_class_name (class_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE teachers (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_number VARCHAR(20) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(254) NOT NULL,
    phone VARCHAR(20),
    PRIMARY KEY (id),
    UNIQUE KEY uq_teachers_staff_number (staff_number),
    UNIQUE KEY uq_teachers_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE classes
    -- Keep assigned form teachers; cascade key updates so class assignments remain valid.
    ADD CONSTRAINT fk_classes_form_teacher
        FOREIGN KEY (form_teacher_id) REFERENCES teachers (id)
        ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE subjects (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    subject_code VARCHAR(12) NOT NULL,
    subject_name VARCHAR(80) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_subjects_subject_code (subject_code),
    UNIQUE KEY uq_subjects_subject_name (subject_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE academic_terms (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    term_name ENUM('First Term', 'Second Term', 'Third Term') NOT NULL,
    academic_year VARCHAR(9) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_academic_terms_name_year (term_name, academic_year),
    CONSTRAINT chk_academic_terms_dates CHECK (start_date <= end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE students (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    admission_number VARCHAR(20) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender ENUM('Female', 'Male') NOT NULL,
    date_of_birth DATE NOT NULL,
    guardian_name VARCHAR(100) NOT NULL,
    guardian_phone VARCHAR(20) NOT NULL,
    date_admitted DATE NOT NULL,
    class_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_students_admission_number (admission_number),
    UNIQUE KEY uq_students_id_class (id, class_id),
    -- Restrict class deletion while students are enrolled; cascade key updates to keep enrollment references valid.
    CONSTRAINT fk_students_class
        FOREIGN KEY (class_id) REFERENCES classes (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE class_subjects (
    class_id BIGINT UNSIGNED NOT NULL,
    subject_id BIGINT UNSIGNED NOT NULL,
    teacher_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (class_id, subject_id),
    KEY idx_class_subjects_teacher (teacher_id),
    -- Delete offerings with their class; cascade key updates to keep the offering linked.
    CONSTRAINT fk_class_subjects_class
        FOREIGN KEY (class_id) REFERENCES classes (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- Keep subjects that are still assigned to a class; cascade key updates to preserve the assignment.
    CONSTRAINT fk_class_subjects_subject
        FOREIGN KEY (subject_id) REFERENCES subjects (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- Keep teachers that are still assigned to a class offering; cascade key updates to preserve the assignment.
    CONSTRAINT fk_class_subjects_teacher
        FOREIGN KEY (teacher_id) REFERENCES teachers (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE results (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    student_id BIGINT UNSIGNED NOT NULL,
    class_id BIGINT UNSIGNED NOT NULL,
    subject_id BIGINT UNSIGNED NOT NULL,
    term_id BIGINT UNSIGNED NOT NULL,
    ca_score DECIMAL(5,2) NOT NULL,
    exam_score DECIMAL(5,2) NOT NULL,
    total_score DECIMAL(5,2)
        GENERATED ALWAYS AS (ca_score + exam_score) STORED,
    remarks VARCHAR(255),
    PRIMARY KEY (id),
    UNIQUE KEY uq_results_student_subject_term (student_id, subject_id, term_id),
    KEY idx_results_class_subject (class_id, subject_id),
    -- Cascade result removal with its student; cascade key updates so a student's class change stays consistent.
    CONSTRAINT fk_results_student_class
        FOREIGN KEY (student_id, class_id) REFERENCES students (id, class_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- Restrict removal of an offering with results; cascade key updates to preserve the offering relationship.
    CONSTRAINT fk_results_class_subject
        FOREIGN KEY (class_id, subject_id) REFERENCES class_subjects (class_id, subject_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    -- Restrict term removal to retain historical results; cascade key updates to keep references valid.
    CONSTRAINT fk_results_term
        FOREIGN KEY (term_id) REFERENCES academic_terms (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_results_ca_score CHECK (ca_score BETWEEN 0.00 AND 40.00),
    CONSTRAINT chk_results_exam_score CHECK (exam_score BETWEEN 0.00 AND 60.00)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE attendance (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    student_id BIGINT UNSIGNED NOT NULL,
    attendance_date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'Late', 'Excused') NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_attendance_student_day (student_id, attendance_date),
    -- Attendance cannot outlive its student, so deletion cascades; key updates cascade to keep the reference valid.
    CONSTRAINT fk_attendance_student
        FOREIGN KEY (student_id) REFERENCES students (id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
