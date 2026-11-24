-- BacaTepat bootstrap schema for MySQL 8.0+
-- Import this file into a new development database. It creates no accounts,
-- sample student records, credentials, or audio files.
-- Audio content belongs in Laravel private storage; only its metadata is here.

CREATE DATABASE IF NOT EXISTS bacatepat
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE bacatepat;

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET time_zone = '+00:00';

-- Accounts. Passwords must be strong hashes created by Laravel's hasher.
CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  username VARCHAR(50) NOT NULL,
  email VARCHAR(100) NULL,
  password_hash VARCHAR(255) NOT NULL COMMENT 'Password hash only; never store plaintext.',
  role ENUM('guru','siswa') NOT NULL,
  status ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  last_login_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_username (username),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_role_status (role, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sanctum-compatible polymorphic token table. Laravel's standard migration
-- may create this instead; use one definition, not both, when bootstrapping Laravel.
CREATE TABLE IF NOT EXISTS personal_access_tokens (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tokenable_type VARCHAR(255) NOT NULL,
  tokenable_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  token VARCHAR(64) NOT NULL COMMENT 'Hashed token from the client token.',
  abilities TEXT NULL,
  last_used_at TIMESTAMP NULL,
  expires_at TIMESTAMP NULL,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_personal_access_tokens_token (token),
  KEY idx_personal_access_tokens_tokenable (tokenable_type, tokenable_id),
  KEY idx_personal_access_tokens_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- One class belongs to one teacher, as specified in BRD AP-03.
CREATE TABLE IF NOT EXISTS classes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  teacher_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(30) NOT NULL,
  grade TINYINT UNSIGNED NOT NULL,
  school_year VARCHAR(9) NOT NULL,
  status ENUM('aktif','arsip') NOT NULL DEFAULT 'aktif',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_classes_teacher_name_year (teacher_id, name, school_year),
  UNIQUE KEY uq_classes_id_teacher (id, teacher_id),
  KEY idx_classes_teacher_status (teacher_id, status),
  CONSTRAINT fk_classes_teacher FOREIGN KEY (teacher_id)
    REFERENCES users (id) ON DELETE RESTRICT,
  CONSTRAINT ck_classes_grade CHECK (grade BETWEEN 1 AND 3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Student profile is separate from the login identity. current_class_id is
-- the current placement; membership rows retain transfer history.
CREATE TABLE IF NOT EXISTS students (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  current_class_id BIGINT UNSIGNED NOT NULL,
  student_number VARCHAR(20) NULL,
  date_of_birth DATE NULL,
  gender ENUM('L','P') NULL,
  guardian_name VARCHAR(100) NOT NULL,
  parent_consent TINYINT UNSIGNED NOT NULL DEFAULT 0,
  ai_consent TINYINT UNSIGNED NOT NULL DEFAULT 0,
  consent_recorded_at DATETIME NULL,
  status ENUM('aktif','nonaktif') NOT NULL DEFAULT 'aktif',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_students_user (user_id),
  UNIQUE KEY uq_students_number (student_number),
  KEY idx_students_current_class_status (current_class_id, status),
  CONSTRAINT fk_students_user FOREIGN KEY (user_id)
    REFERENCES users (id) ON DELETE RESTRICT,
  CONSTRAINT fk_students_current_class FOREIGN KEY (current_class_id)
    REFERENCES classes (id) ON DELETE RESTRICT,
  CONSTRAINT ck_students_parent_consent CHECK (parent_consent IN (0,1)),
  CONSTRAINT ck_students_ai_consent CHECK (ai_consent IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS student_class_memberships (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL,
  started_at DATETIME NOT NULL,
  ended_at DATETIME NULL,
  recorded_by_teacher_id BIGINT UNSIGNED NOT NULL,
  active_student_id BIGINT UNSIGNED GENERATED ALWAYS AS
    (CASE WHEN ended_at IS NULL THEN student_id ELSE NULL END) STORED,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_student_membership_active (active_student_id),
  KEY idx_student_memberships_class_period (class_id, started_at, ended_at),
  CONSTRAINT fk_student_memberships_student FOREIGN KEY (student_id)
    REFERENCES students (id) ON DELETE RESTRICT,
  CONSTRAINT fk_student_memberships_class FOREIGN KEY (class_id)
    REFERENCES classes (id) ON DELETE RESTRICT,
  CONSTRAINT fk_student_memberships_teacher FOREIGN KEY (recorded_by_teacher_id)
    REFERENCES users (id) ON DELETE RESTRICT,
  CONSTRAINT ck_student_membership_period CHECK (ended_at IS NULL OR ended_at >= started_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Consent changes are auditable. The current flags on students are a query
-- convenience and must be updated in the same transaction as this event log.
CREATE TABLE IF NOT EXISTS student_consent_events (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id BIGINT UNSIGNED NOT NULL,
  recorded_by_teacher_id BIGINT UNSIGNED NOT NULL,
  guardian_name_snapshot VARCHAR(100) NOT NULL,
  parent_consent TINYINT UNSIGNED NOT NULL,
  ai_consent TINYINT UNSIGNED NOT NULL,
  recorded_at DATETIME NOT NULL,
  note VARCHAR(255) NULL,
  PRIMARY KEY (id),
  KEY idx_consent_events_student_time (student_id, recorded_at),
  CONSTRAINT fk_consent_events_student FOREIGN KEY (student_id)
    REFERENCES students (id) ON DELETE RESTRICT,
  CONSTRAINT fk_consent_events_teacher FOREIGN KEY (recorded_by_teacher_id)
    REFERENCES users (id) ON DELETE RESTRICT,
  CONSTRAINT ck_consent_parent CHECK (parent_consent IN (0,1)),
  CONSTRAINT ck_consent_ai CHECK (ai_consent IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reference taxonomy used by content, answer snapshots, and mastery history.
CREATE TABLE IF NOT EXISTS learning_aspects (
  code VARCHAR(24) NOT NULL,
  label VARCHAR(40) NOT NULL,
  sequence_no TINYINT UNSIGNED NOT NULL,
  prerequisite_code VARCHAR(24) NULL,
  PRIMARY KEY (code),
  UNIQUE KEY uq_learning_aspects_sequence (sequence_no),
  CONSTRAINT fk_learning_aspects_prerequisite FOREIGN KEY (prerequisite_code)
    REFERENCES learning_aspects (code) ON DELETE RESTRICT,
  CONSTRAINT ck_learning_aspects_sequence CHECK (sequence_no BETWEEN 1 AND 4)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO learning_aspects (code, label, sequence_no, prerequisite_code) VALUES
  ('huruf','Huruf',1,NULL),
  ('suku_kata','Suku kata',2,'huruf'),
  ('kata','Kata',3,'suku_kata'),
  ('kalimat','Kalimat',4,'kata')
AS incoming_aspect
ON DUPLICATE KEY UPDATE
  label = incoming_aspect.label, sequence_no = incoming_aspect.sequence_no,
  prerequisite_code = incoming_aspect.prerequisite_code;

CREATE TABLE IF NOT EXISTS materials (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  teacher_id BIGINT UNSIGNED NOT NULL,
  aspect_code VARCHAR(24) NOT NULL,
  level TINYINT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  content MEDIUMTEXT NOT NULL,
  content_asset_key VARCHAR(255) NULL,
  ai_generated TINYINT UNSIGNED NOT NULL DEFAULT 0,
  status ENUM('draft','active','archived') NOT NULL DEFAULT 'draft',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_materials_selection (aspect_code, level, status),
  KEY idx_materials_teacher_status (teacher_id, status),
  CONSTRAINT fk_materials_teacher FOREIGN KEY (teacher_id)
    REFERENCES users (id) ON DELETE RESTRICT,
  CONSTRAINT fk_materials_aspect FOREIGN KEY (aspect_code)
    REFERENCES learning_aspects (code) ON DELETE RESTRICT,
  CONSTRAINT ck_materials_level CHECK (level BETWEEN 1 AND 3),
  CONSTRAINT ck_materials_ai_generated CHECK (ai_generated IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS questions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  teacher_id BIGINT UNSIGNED NOT NULL,
  material_id BIGINT UNSIGNED NULL COMMENT 'NULL for questions not bound to a learning material, such as diagnostics.',
  aspect_code VARCHAR(24) NOT NULL,
  level TINYINT UNSIGNED NOT NULL,
  question_type ENUM('multiple_choice','oral_reading') NOT NULL,
  usage_scope ENUM('diagnostic','practice','both') NOT NULL DEFAULT 'both',
  prompt TEXT NOT NULL,
  stimulus_text TEXT NULL,
  stimulus_asset_key VARCHAR(255) NULL,
  target_text VARCHAR(500) NULL COMMENT 'Required for oral reading; validated by the application.',
  hint TEXT NULL,
  explanation TEXT NULL,
  ai_generated TINYINT UNSIGNED NOT NULL DEFAULT 0,
  review_status ENUM('draft','approved','rejected','inactive') NOT NULL DEFAULT 'draft',
  reviewed_by_teacher_id BIGINT UNSIGNED NULL,
  reviewed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_questions_selection (aspect_code, level, review_status, usage_scope),
  KEY idx_questions_material (material_id, review_status, usage_scope),
  KEY idx_questions_teacher (teacher_id, review_status),
  CONSTRAINT fk_questions_teacher FOREIGN KEY (teacher_id)
    REFERENCES users (id) ON DELETE RESTRICT,
  CONSTRAINT fk_questions_material FOREIGN KEY (material_id)
    REFERENCES materials (id) ON DELETE SET NULL,
  CONSTRAINT fk_questions_aspect FOREIGN KEY (aspect_code)
    REFERENCES learning_aspects (code) ON DELETE RESTRICT,
  CONSTRAINT fk_questions_reviewer FOREIGN KEY (reviewed_by_teacher_id)
    REFERENCES users (id) ON DELETE SET NULL,
  CONSTRAINT ck_questions_level CHECK (level BETWEEN 1 AND 3),
  CONSTRAINT ck_questions_ai_generated CHECK (ai_generated IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS question_options (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  question_id BIGINT UNSIGNED NOT NULL,
  position SMALLINT UNSIGNED NOT NULL,
  option_text VARCHAR(500) NOT NULL,
  option_asset_key VARCHAR(255) NULL,
  is_correct TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_question_options_position (question_id, position),
  KEY idx_question_options_answer (question_id, is_correct),
  CONSTRAINT fk_question_options_question FOREIGN KEY (question_id)
    REFERENCES questions (id) ON DELETE CASCADE,
  CONSTRAINT ck_question_options_correct CHECK (is_correct IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS diagnostic_tests (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  teacher_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(150) NOT NULL,
  status ENUM('draft','active','finished') NOT NULL DEFAULT 'draft',
  activated_at DATETIME NULL,
  finished_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_diagnostic_tests_class_status (class_id, status),
  CONSTRAINT fk_diagnostic_tests_owner_class FOREIGN KEY (class_id, teacher_id)
    REFERENCES classes (id, teacher_id) ON DELETE RESTRICT,
  CONSTRAINT fk_diagnostic_tests_teacher FOREIGN KEY (teacher_id)
    REFERENCES users (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS diagnostic_test_questions (
  diagnostic_test_id BIGINT UNSIGNED NOT NULL,
  question_id BIGINT UNSIGNED NOT NULL,
  position SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (diagnostic_test_id, question_id),
  UNIQUE KEY uq_diagnostic_test_position (diagnostic_test_id, position),
  KEY idx_diagnostic_test_questions_question (question_id),
  CONSTRAINT fk_diagnostic_test_questions_test FOREIGN KEY (diagnostic_test_id)
    REFERENCES diagnostic_tests (id) ON DELETE CASCADE,
  CONSTRAINT fk_diagnostic_test_questions_question FOREIGN KEY (question_id)
    REFERENCES questions (id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS diagnostic_attempts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id BIGINT UNSIGNED NOT NULL,
  diagnostic_test_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL COMMENT 'Class-attempt snapshot for access checks and reporting after transfer.',
  status ENUM('in_progress','waiting_teacher','completed','abandoned') NOT NULL DEFAULT 'in_progress',
  overall_score DECIMAL(5,2) NULL,
  started_at DATETIME NOT NULL,
  finished_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_diagnostic_attempt_student_test (student_id, diagnostic_test_id),
  KEY idx_diagnostic_attempt_class_status (class_id, status),
  KEY idx_diagnostic_attempt_student_time (student_id, started_at),
  CONSTRAINT fk_diagnostic_attempt_student FOREIGN KEY (student_id)
    REFERENCES students (id) ON DELETE RESTRICT,
  CONSTRAINT fk_diagnostic_attempt_test FOREIGN KEY (diagnostic_test_id)
    REFERENCES diagnostic_tests (id) ON DELETE RESTRICT,
  CONSTRAINT fk_diagnostic_attempt_class FOREIGN KEY (class_id)
    REFERENCES classes (id) ON DELETE RESTRICT,
  CONSTRAINT ck_diagnostic_attempt_score CHECK (overall_score IS NULL OR overall_score BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS diagnostic_attempt_answers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  diagnostic_attempt_id BIGINT UNSIGNED NOT NULL,
  question_id BIGINT UNSIGNED NULL,
  aspect_code VARCHAR(24) NOT NULL,
  level_snapshot TINYINT UNSIGNED NOT NULL,
  question_type ENUM('multiple_choice','oral_reading') NOT NULL,
  prompt_snapshot TEXT NOT NULL,
  stimulus_text_snapshot TEXT NULL,
  stimulus_asset_key_snapshot VARCHAR(255) NULL,
  target_text_snapshot VARCHAR(500) NULL,
  selected_answer VARCHAR(500) NULL,
  correct_answer_snapshot VARCHAR(500) NULL,
  is_correct TINYINT UNSIGNED NULL COMMENT 'NULL until teacher evaluates an oral-reading answer.',
  score DECIMAL(5,2) NULL,
  answered_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_diagnostic_attempt_question (diagnostic_attempt_id, question_id),
  KEY idx_diagnostic_answers_aspect (diagnostic_attempt_id, aspect_code),
  CONSTRAINT fk_diagnostic_answers_attempt FOREIGN KEY (diagnostic_attempt_id)
    REFERENCES diagnostic_attempts (id) ON DELETE CASCADE,
  CONSTRAINT fk_diagnostic_answers_question FOREIGN KEY (question_id)
    REFERENCES questions (id) ON DELETE SET NULL,
  CONSTRAINT fk_diagnostic_answers_aspect FOREIGN KEY (aspect_code)
    REFERENCES learning_aspects (code) ON DELETE RESTRICT,
  CONSTRAINT ck_diagnostic_answers_level CHECK (level_snapshot BETWEEN 1 AND 3),
  CONSTRAINT ck_diagnostic_answers_correct CHECK (is_correct IS NULL OR is_correct IN (0,1)),
  CONSTRAINT ck_diagnostic_answers_score CHECK (score IS NULL OR score BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS diagnostic_answer_options (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  diagnostic_answer_id BIGINT UNSIGNED NOT NULL,
  position SMALLINT UNSIGNED NOT NULL,
  option_text_snapshot VARCHAR(500) NOT NULL,
  option_asset_key_snapshot VARCHAR(255) NULL,
  is_correct_snapshot TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_diagnostic_answer_option_position (diagnostic_answer_id, position),
  CONSTRAINT fk_diagnostic_answer_options_answer FOREIGN KEY (diagnostic_answer_id)
    REFERENCES diagnostic_attempt_answers (id) ON DELETE CASCADE,
  CONSTRAINT ck_diagnostic_answer_option_correct CHECK (is_correct_snapshot IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS recommendations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL,
  material_id BIGINT UNSIGNED NOT NULL,
  aspect_code VARCHAR(24) NOT NULL,
  target_level TINYINT UNSIGNED NOT NULL,
  source ENUM('system','teacher') NOT NULL,
  reason VARCHAR(500) NOT NULL,
  created_by_teacher_id BIGINT UNSIGNED NULL COMMENT 'Required when source is teacher; validated transactionally.',
  status ENUM('active','completed','cancelled','superseded') NOT NULL DEFAULT 'active',
  completed_by_practice_attempt_id BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL,
  closed_at DATETIME NULL,
  active_student_id BIGINT UNSIGNED GENERATED ALWAYS AS
    (CASE WHEN status = 'active' THEN student_id ELSE NULL END) STORED,
  PRIMARY KEY (id),
  UNIQUE KEY uq_recommendations_one_active_per_student (active_student_id),
  KEY idx_recommendations_class_status (class_id, status),
  KEY idx_recommendations_student_history (student_id, created_at),
  KEY idx_recommendations_material (material_id, status),
  CONSTRAINT fk_recommendations_student FOREIGN KEY (student_id)
    REFERENCES students (id) ON DELETE RESTRICT,
  CONSTRAINT fk_recommendations_class FOREIGN KEY (class_id)
    REFERENCES classes (id) ON DELETE RESTRICT,
  CONSTRAINT fk_recommendations_material FOREIGN KEY (material_id)
    REFERENCES materials (id) ON DELETE RESTRICT,
  CONSTRAINT fk_recommendations_aspect FOREIGN KEY (aspect_code)
    REFERENCES learning_aspects (code) ON DELETE RESTRICT,
  CONSTRAINT fk_recommendations_teacher FOREIGN KEY (created_by_teacher_id)
    REFERENCES users (id) ON DELETE RESTRICT,
  CONSTRAINT ck_recommendations_level CHECK (target_level BETWEEN 1 AND 3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS practice_attempts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL COMMENT 'Class-attempt snapshot for access checks and reporting after transfer.',
  material_id BIGINT UNSIGNED NULL,
  recommendation_id BIGINT UNSIGNED NULL,
  material_title_snapshot VARCHAR(150) NOT NULL,
  aspect_code VARCHAR(24) NOT NULL,
  level_snapshot TINYINT UNSIGNED NOT NULL,
  attempt_number SMALLINT UNSIGNED NOT NULL,
  status ENUM('in_progress','waiting_teacher','completed','abandoned') NOT NULL DEFAULT 'in_progress',
  score DECIMAL(5,2) NULL,
  correct_count SMALLINT UNSIGNED NULL,
  question_count SMALLINT UNSIGNED NULL,
  completion_token VARCHAR(100) NULL COMMENT 'Idempotency key for retrying a completion request.',
  started_at DATETIME NOT NULL,
  finished_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_practice_attempt_completion_token (student_id, completion_token),
  KEY idx_practice_attempt_student_time (student_id, started_at),
  KEY idx_practice_attempt_class_time (class_id, started_at),
  KEY idx_practice_attempt_material (material_id, student_id),
  KEY idx_practice_attempt_recommendation (recommendation_id),
  CONSTRAINT fk_practice_attempt_student FOREIGN KEY (student_id)
    REFERENCES students (id) ON DELETE RESTRICT,
  CONSTRAINT fk_practice_attempt_class FOREIGN KEY (class_id)
    REFERENCES classes (id) ON DELETE RESTRICT,
  CONSTRAINT fk_practice_attempt_material FOREIGN KEY (material_id)
    REFERENCES materials (id) ON DELETE SET NULL,
  CONSTRAINT fk_practice_attempt_recommendation FOREIGN KEY (recommendation_id)
    REFERENCES recommendations (id) ON DELETE SET NULL,
  CONSTRAINT fk_practice_attempt_aspect FOREIGN KEY (aspect_code)
    REFERENCES learning_aspects (code) ON DELETE RESTRICT,
  CONSTRAINT ck_practice_attempt_level CHECK (level_snapshot BETWEEN 1 AND 3),
  CONSTRAINT ck_practice_attempt_score CHECK (score IS NULL OR score BETWEEN 0 AND 100),
  CONSTRAINT ck_practice_attempt_counts CHECK (
    (correct_count IS NULL AND question_count IS NULL) OR
    (correct_count IS NOT NULL AND question_count IS NOT NULL AND correct_count <= question_count)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Added after practice_attempts to resolve the recommendation/attempt cycle.
-- The conditional form permits re-importing this bootstrap file without a
-- duplicate-constraint error. It is not a schema migration mechanism.
SET @recommendation_completion_fk_exists = (
  SELECT COUNT(*)
  FROM information_schema.REFERENTIAL_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'recommendations'
    AND CONSTRAINT_NAME = 'fk_recommendations_completed_attempt'
);
SET @recommendation_completion_fk_ddl = IF(
  @recommendation_completion_fk_exists = 0,
  'ALTER TABLE recommendations ADD CONSTRAINT fk_recommendations_completed_attempt FOREIGN KEY (completed_by_practice_attempt_id) REFERENCES practice_attempts (id) ON DELETE SET NULL',
  'SELECT 1'
);
PREPARE recommendation_completion_fk_statement FROM @recommendation_completion_fk_ddl;
EXECUTE recommendation_completion_fk_statement;
DEALLOCATE PREPARE recommendation_completion_fk_statement;

CREATE TABLE IF NOT EXISTS practice_attempt_answers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  practice_attempt_id BIGINT UNSIGNED NOT NULL,
  question_id BIGINT UNSIGNED NULL,
  aspect_code VARCHAR(24) NOT NULL,
  level_snapshot TINYINT UNSIGNED NOT NULL,
  question_type ENUM('multiple_choice','oral_reading') NOT NULL,
  prompt_snapshot TEXT NOT NULL,
  stimulus_text_snapshot TEXT NULL,
  stimulus_asset_key_snapshot VARCHAR(255) NULL,
  target_text_snapshot VARCHAR(500) NULL,
  selected_answer VARCHAR(500) NULL,
  correct_answer_snapshot VARCHAR(500) NULL,
  is_correct TINYINT UNSIGNED NULL,
  score DECIMAL(5,2) NULL,
  answered_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_practice_attempt_question (practice_attempt_id, question_id),
  KEY idx_practice_answers_aspect (practice_attempt_id, aspect_code),
  CONSTRAINT fk_practice_answers_attempt FOREIGN KEY (practice_attempt_id)
    REFERENCES practice_attempts (id) ON DELETE CASCADE,
  CONSTRAINT fk_practice_answers_question FOREIGN KEY (question_id)
    REFERENCES questions (id) ON DELETE SET NULL,
  CONSTRAINT fk_practice_answers_aspect FOREIGN KEY (aspect_code)
    REFERENCES learning_aspects (code) ON DELETE RESTRICT,
  CONSTRAINT ck_practice_answers_level CHECK (level_snapshot BETWEEN 1 AND 3),
  CONSTRAINT ck_practice_answers_correct CHECK (is_correct IS NULL OR is_correct IN (0,1)),
  CONSTRAINT ck_practice_answers_score CHECK (score IS NULL OR score BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS practice_answer_options (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  practice_answer_id BIGINT UNSIGNED NOT NULL,
  position SMALLINT UNSIGNED NOT NULL,
  option_text_snapshot VARCHAR(500) NOT NULL,
  option_asset_key_snapshot VARCHAR(255) NULL,
  is_correct_snapshot TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_practice_answer_option_position (practice_answer_id, position),
  CONSTRAINT fk_practice_answer_options_answer FOREIGN KEY (practice_answer_id)
    REFERENCES practice_attempt_answers (id) ON DELETE CASCADE,
  CONSTRAINT ck_practice_answer_option_correct CHECK (is_correct_snapshot IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS material_gaps (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL,
  aspect_code VARCHAR(24) NOT NULL,
  target_level TINYINT UNSIGNED NOT NULL,
  reason VARCHAR(500) NOT NULL,
  created_at DATETIME NOT NULL,
  resolved_at DATETIME NULL,
  resolved_by_teacher_id BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  KEY idx_material_gaps_open (class_id, resolved_at, aspect_code, target_level),
  KEY idx_material_gaps_student (student_id, created_at),
  CONSTRAINT fk_material_gaps_student FOREIGN KEY (student_id)
    REFERENCES students (id) ON DELETE RESTRICT,
  CONSTRAINT fk_material_gaps_class FOREIGN KEY (class_id)
    REFERENCES classes (id) ON DELETE RESTRICT,
  CONSTRAINT fk_material_gaps_aspect FOREIGN KEY (aspect_code)
    REFERENCES learning_aspects (code) ON DELETE RESTRICT,
  CONSTRAINT fk_material_gaps_resolver FOREIGN KEY (resolved_by_teacher_id)
    REFERENCES users (id) ON DELETE RESTRICT,
  CONSTRAINT ck_material_gaps_level CHECK (target_level BETWEEN 1 AND 3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS voice_recordings (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id BIGINT UNSIGNED NOT NULL,
  question_id BIGINT UNSIGNED NULL,
  diagnostic_attempt_id BIGINT UNSIGNED NULL,
  practice_attempt_id BIGINT UNSIGNED NULL,
  target_text_snapshot VARCHAR(500) NOT NULL,
  storage_disk VARCHAR(40) NOT NULL DEFAULT 'private',
  private_storage_path VARCHAR(500) NULL COMMENT 'Never expose as a public URL; NULL after file deletion.',
  mime_type VARCHAR(80) NOT NULL,
  size_bytes INT UNSIGNED NOT NULL,
  duration_seconds SMALLINT UNSIGNED NOT NULL,
  parent_consent_snapshot TINYINT UNSIGNED NOT NULL,
  ai_consent_snapshot TINYINT UNSIGNED NOT NULL,
  status ENUM('uploaded','evaluated','rejected','file_deleted') NOT NULL DEFAULT 'uploaded',
  submitted_at DATETIME NOT NULL,
  delete_after DATE NULL,
  file_deleted_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_voice_recordings_student_time (student_id, submitted_at),
  KEY idx_voice_recordings_queue (status, submitted_at),
  KEY idx_voice_recordings_retention (delete_after, file_deleted_at),
  KEY idx_voice_recordings_diagnostic (diagnostic_attempt_id),
  KEY idx_voice_recordings_practice (practice_attempt_id),
  CONSTRAINT fk_voice_recordings_student FOREIGN KEY (student_id)
    REFERENCES students (id) ON DELETE RESTRICT,
  CONSTRAINT fk_voice_recordings_question FOREIGN KEY (question_id)
    REFERENCES questions (id) ON DELETE SET NULL,
  CONSTRAINT fk_voice_recordings_diagnostic FOREIGN KEY (diagnostic_attempt_id)
    REFERENCES diagnostic_attempts (id) ON DELETE RESTRICT,
  CONSTRAINT fk_voice_recordings_practice FOREIGN KEY (practice_attempt_id)
    REFERENCES practice_attempts (id) ON DELETE RESTRICT,
  CONSTRAINT ck_voice_recordings_size CHECK (size_bytes BETWEEN 1 AND 5242880),
  CONSTRAINT ck_voice_recordings_duration CHECK (duration_seconds BETWEEN 1 AND 60),
  CONSTRAINT ck_voice_recordings_parent_consent CHECK (parent_consent_snapshot IN (0,1)),
  CONSTRAINT ck_voice_recordings_ai_consent CHECK (ai_consent_snapshot IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audio_evaluations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  recording_id BIGINT UNSIGNED NOT NULL,
  teacher_id BIGINT UNSIGNED NOT NULL,
  accuracy_score TINYINT UNSIGNED NOT NULL,
  fluency_score TINYINT UNSIGNED NOT NULL,
  comment TEXT NULL,
  advice TEXT NULL,
  evaluated_at DATETIME NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_audio_evaluations_recording (recording_id),
  KEY idx_audio_evaluations_teacher (teacher_id, evaluated_at),
  CONSTRAINT fk_audio_evaluations_recording FOREIGN KEY (recording_id)
    REFERENCES voice_recordings (id) ON DELETE RESTRICT,
  CONSTRAINT fk_audio_evaluations_teacher FOREIGN KEY (teacher_id)
    REFERENCES users (id) ON DELETE RESTRICT,
  CONSTRAINT ck_audio_evaluations_accuracy CHECK (accuracy_score BETWEEN 0 AND 100),
  CONSTRAINT ck_audio_evaluations_fluency CHECK (fluency_score BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Append-only revisions preserve earlier teacher judgments while the parent
-- evaluation row holds the current version required by the BRD.
CREATE TABLE IF NOT EXISTS audio_evaluation_revisions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  evaluation_id BIGINT UNSIGNED NOT NULL,
  revision_no SMALLINT UNSIGNED NOT NULL,
  teacher_id BIGINT UNSIGNED NOT NULL,
  accuracy_score TINYINT UNSIGNED NOT NULL,
  fluency_score TINYINT UNSIGNED NOT NULL,
  comment TEXT NULL,
  advice TEXT NULL,
  revised_at DATETIME NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_audio_evaluation_revision (evaluation_id, revision_no),
  KEY idx_audio_evaluation_revisions_teacher (teacher_id, revised_at),
  CONSTRAINT fk_audio_evaluation_revisions_evaluation FOREIGN KEY (evaluation_id)
    REFERENCES audio_evaluations (id) ON DELETE RESTRICT,
  CONSTRAINT fk_audio_evaluation_revisions_teacher FOREIGN KEY (teacher_id)
    REFERENCES users (id) ON DELETE RESTRICT,
  CONSTRAINT ck_audio_evaluation_revision_no CHECK (revision_no >= 1),
  CONSTRAINT ck_audio_evaluation_revision_accuracy CHECK (accuracy_score BETWEEN 0 AND 100),
  CONSTRAINT ck_audio_evaluation_revision_fluency CHECK (fluency_score BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ai_audio_analyses (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  recording_id BIGINT UNSIGNED NOT NULL,
  status ENUM('queued','running','succeeded','failed','skipped') NOT NULL,
  transcript MEDIUMTEXT NULL,
  missed_words JSON NULL,
  changed_words JSON NULL,
  repeated_words JSON NULL,
  similarity_score DECIMAL(5,2) NULL COMMENT 'Indicative only; never an official reading score.',
  model_name VARCHAR(100) NULL,
  error_summary VARCHAR(500) NULL,
  requested_at DATETIME NOT NULL,
  completed_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_ai_audio_analyses_recording (recording_id, requested_at),
  KEY idx_ai_audio_analyses_queue (status, requested_at),
  CONSTRAINT fk_ai_audio_analyses_recording FOREIGN KEY (recording_id)
    REFERENCES voice_recordings (id) ON DELETE RESTRICT,
  CONSTRAINT ck_ai_audio_similarity CHECK (similarity_score IS NULL OR similarity_score BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS ai_usage_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  teacher_id BIGINT UNSIGNED NULL,
  job_type ENUM('material_generation','question_generation','audio_analysis','advice_narrative') NOT NULL,
  model_name VARCHAR(100) NULL,
  input_tokens INT UNSIGNED NULL,
  output_tokens INT UNSIGNED NULL,
  audio_duration_seconds SMALLINT UNSIGNED NULL,
  status ENUM('succeeded','failed') NOT NULL,
  duration_ms INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ai_usage_teacher_time (teacher_id, created_at),
  KEY idx_ai_usage_job_time (job_type, created_at),
  CONSTRAINT fk_ai_usage_teacher FOREIGN KEY (teacher_id)
    REFERENCES users (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Append-only event history. Exactly one source reference is required. Keep
-- source records; use RESTRICT and insert a new row for each recalculation.
CREATE TABLE IF NOT EXISTS mastery_history (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  student_id BIGINT UNSIGNED NOT NULL,
  class_id BIGINT UNSIGNED NOT NULL,
  aspect_code VARCHAR(24) NOT NULL,
  observed_level TINYINT UNSIGNED NOT NULL,
  target_aspect_code VARCHAR(24) NULL,
  target_level TINYINT UNSIGNED NULL,
  score DECIMAL(5,2) NOT NULL,
  mastery_status ENUM('not_mastered','practicing','mastered') NOT NULL,
  needs_teacher_support TINYINT UNSIGNED NOT NULL DEFAULT 0,
  source_type ENUM('diagnostic','practice','audio_evaluation') NOT NULL,
  diagnostic_attempt_id BIGINT UNSIGNED NULL,
  practice_attempt_id BIGINT UNSIGNED NULL,
  audio_evaluation_revision_id BIGINT UNSIGNED NULL,
  reason VARCHAR(500) NOT NULL,
  recorded_at DATETIME NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_mastery_source_diag (diagnostic_attempt_id, aspect_code),
  UNIQUE KEY uq_mastery_source_practice (practice_attempt_id, aspect_code),
  UNIQUE KEY uq_mastery_source_audio_revision (audio_evaluation_revision_id, aspect_code),
  KEY idx_mastery_history_student_aspect_time (student_id, aspect_code, recorded_at),
  KEY idx_mastery_history_class_aspect_time (class_id, aspect_code, recorded_at),
  KEY idx_mastery_history_support (class_id, needs_teacher_support, recorded_at),
  CONSTRAINT fk_mastery_history_student FOREIGN KEY (student_id)
    REFERENCES students (id) ON DELETE RESTRICT,
  CONSTRAINT fk_mastery_history_class FOREIGN KEY (class_id)
    REFERENCES classes (id) ON DELETE RESTRICT,
  CONSTRAINT fk_mastery_history_aspect FOREIGN KEY (aspect_code)
    REFERENCES learning_aspects (code) ON DELETE RESTRICT,
  CONSTRAINT fk_mastery_history_target_aspect FOREIGN KEY (target_aspect_code)
    REFERENCES learning_aspects (code) ON DELETE RESTRICT,
  CONSTRAINT fk_mastery_history_diagnostic FOREIGN KEY (diagnostic_attempt_id)
    REFERENCES diagnostic_attempts (id) ON DELETE RESTRICT,
  CONSTRAINT fk_mastery_history_practice FOREIGN KEY (practice_attempt_id)
    REFERENCES practice_attempts (id) ON DELETE RESTRICT,
  CONSTRAINT fk_mastery_history_audio_revision FOREIGN KEY (audio_evaluation_revision_id)
    REFERENCES audio_evaluation_revisions (id) ON DELETE RESTRICT,
  CONSTRAINT ck_mastery_history_source CHECK (
    (source_type = 'diagnostic' AND diagnostic_attempt_id IS NOT NULL AND practice_attempt_id IS NULL AND audio_evaluation_revision_id IS NULL) OR
    (source_type = 'practice' AND diagnostic_attempt_id IS NULL AND practice_attempt_id IS NOT NULL AND audio_evaluation_revision_id IS NULL) OR
    (source_type = 'audio_evaluation' AND diagnostic_attempt_id IS NULL AND practice_attempt_id IS NULL AND audio_evaluation_revision_id IS NOT NULL)
  ),
  CONSTRAINT ck_mastery_history_level CHECK (observed_level BETWEEN 1 AND 3),
  CONSTRAINT ck_mastery_history_target_level CHECK (target_level IS NULL OR target_level BETWEEN 1 AND 3),
  CONSTRAINT ck_mastery_history_score CHECK (score BETWEEN 0 AND 100),
  CONSTRAINT ck_mastery_history_support CHECK (needs_teacher_support IN (0,1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Laravel database queue support. Job payloads should contain IDs only, never
-- student names, passwords, raw audio, or public storage URLs.
CREATE TABLE IF NOT EXISTS jobs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  queue VARCHAR(255) NOT NULL,
  payload LONGTEXT NOT NULL,
  attempts TINYINT UNSIGNED NOT NULL,
  reserved_at INT UNSIGNED NULL,
  available_at INT UNSIGNED NOT NULL,
  created_at INT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  KEY idx_jobs_queue (queue)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS failed_jobs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid VARCHAR(255) NOT NULL,
  connection TEXT NOT NULL,
  queue TEXT NOT NULL,
  payload LONGTEXT NOT NULL,
  exception LONGTEXT NOT NULL,
  failed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_failed_jobs_uuid (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
