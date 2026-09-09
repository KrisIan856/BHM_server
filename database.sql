CREATE DATABASE IF NOT EXISTS boarding_house
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE boarding_house;

-- ─── Users ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username      VARCHAR(50)  NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('guardian','boarder') NOT NULL,
  created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ─── Boarders (extended profile) ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS boarders (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id           INT UNSIGNED NOT NULL,
  name              VARCHAR(120) NOT NULL,
  room              VARCHAR(10)  NOT NULL,
  floor             VARCHAR(5)   NOT NULL,
  phone             VARCHAR(20),
  email             VARCHAR(120),
  join_date         DATE,
  monthly_rate      DECIMAL(10,2) DEFAULT 0,
  due_day           TINYINT       DEFAULT 10,
  grace_period_days TINYINT       DEFAULT 3,
  late_penalty_type ENUM('flat','percentage') DEFAULT 'flat',
  late_penalty_amount DECIMAL(10,2) DEFAULT 0,
  emergency_name         VARCHAR(120),
  emergency_relationship VARCHAR(60),
  emergency_phone        VARCHAR(20),
  job               VARCHAR(120),
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── Payment Records ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payment_records (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  boarder_id      INT UNSIGNED NOT NULL,
  period          VARCHAR(7)   NOT NULL COMMENT 'YYYY-MM',
  amount          DECIMAL(10,2) NOT NULL,
  paid_date       DATE,
  method          ENUM('cash','gcash','bank_transfer','online'),
  status          ENUM('paid','pending','overdue') DEFAULT 'pending',
  receipt_status  ENUM('pending_review','verified','rejected'),
  receipt_file    VARCHAR(255),
  rejection_reason TEXT,
  recorded_by     ENUM('boarder','guardian'),
  verified_at     TIMESTAMP NULL,
  verified_by     INT UNSIGNED,
  notes           TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (boarder_id) REFERENCES boarders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── Attendance Sessions ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS attendance_sessions (
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  type           ENUM('morning','evening') NOT NULL,
  date           DATE NOT NULL,
  window_start   TIME NOT NULL,
  window_end     TIME NOT NULL,
  qr_validity_mins TINYINT DEFAULT 5
) ENGINE=InnoDB;

-- ─── Attendance Records ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS attendance_records (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  boarder_id      INT UNSIGNED NOT NULL,
  session_id      INT UNSIGNED NOT NULL,
  status          ENUM('present','absent') DEFAULT 'absent',
  check_in_time   TIMESTAMP NULL,
  method          ENUM('qr','manual') DEFAULT 'qr',
  override_reason TEXT,
  overridden_by   INT UNSIGNED,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (boarder_id)  REFERENCES boarders(id) ON DELETE CASCADE,
  FOREIGN KEY (session_id)  REFERENCES attendance_sessions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── Announcements ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS announcements (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title      VARCHAR(200) NOT NULL,
  body       TEXT NOT NULL,
  priority   ENUM('normal','critical') DEFAULT 'normal',
  recipients JSON COMMENT 'Array of boarder IDs or "all"',
  sent_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  sent_by    INT UNSIGNED NOT NULL,
  FOREIGN KEY (sent_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- ─── Visitor Log ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS visitor_entries (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visitor_name VARCHAR(120) NOT NULL,
  boarder_id  INT UNSIGNED NOT NULL,
  purpose     VARCHAR(255),
  time_in     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  time_out    TIMESTAMP NULL,
  date        DATE NOT NULL,
  FOREIGN KEY (boarder_id) REFERENCES boarders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── Incidents ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS incidents (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  type        ENUM('missed_curfew','sos','missed_worship','maintenance','other'),
  boarder_id  INT UNSIGNED,
  title       VARCHAR(200) NOT NULL,
  description TEXT,
  timestamp   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved    BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (boarder_id) REFERENCES boarders(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ─── Maintenance Reports ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS maintenance_reports (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  boarder_id   INT UNSIGNED NOT NULL,
  room         VARCHAR(10) NOT NULL,
  category     ENUM('plumbing','electrical','furniture','appliance','other'),
  description  TEXT,
  status       ENUM('open','in_progress','resolved') DEFAULT 'open',
  submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at  TIMESTAMP NULL,
  FOREIGN KEY (boarder_id) REFERENCES boarders(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ─── Curfew Records ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS curfew_records (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  boarder_id   INT UNSIGNED NOT NULL,
  date         DATE NOT NULL,
  curfew_time  TIME NOT NULL,
  checked_in_at TIMESTAMP NULL,
  status       ENUM('compliant','late','absent','pending') DEFAULT 'pending',
  FOREIGN KEY (boarder_id) REFERENCES boarders(id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- =============================================================================
-- MOCK DATA INSERTION
-- All default passwords for mock user accounts below are: password123
-- (Bcrypt Hash: $2a$10$gZfol5NlmLAbcDgOXXrLMu4uSI/FEWk2bFNyJK0mUMf3gQlfpUKTC)
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ─── 1. Mock Users ───────────────────────────────────────────────────────────
INSERT INTO users (id, username, password_hash, role, created_at) VALUES
(1, 'admin_guardian', '$2a$10$gZfol5NlmLAbcDgOXXrLMu4uSI/FEWk2bFNyJK0mUMf3gQlfpUKTC', 'guardian', '2024-01-01 08:00:00'),
(2, 'landlord_mary',  '$2a$10$gZfol5NlmLAbcDgOXXrLMu4uSI/FEWk2bFNyJK0mUMf3gQlfpUKTC', 'guardian', '2024-01-01 08:30:00'),
(3, 'juan_dela_cruz', '$2a$10$gZfol5NlmLAbcDgOXXrLMu4uSI/FEWk2bFNyJK0mUMf3gQlfpUKTC', 'boarder',  '2024-01-15 09:00:00'),
(4, 'maria_santos',   '$2a$10$gZfol5NlmLAbcDgOXXrLMu4uSI/FEWk2bFNyJK0mUMf3gQlfpUKTC', 'boarder',  '2024-02-01 10:00:00'),
(5, 'alex_gonzales',  '$2a$10$gZfol5NlmLAbcDgOXXrLMu4uSI/FEWk2bFNyJK0mUMf3gQlfpUKTC', 'boarder',  '2024-03-10 11:15:00'),
(6, 'sarah_geronimo', '$2a$10$gZfol5NlmLAbcDgOXXrLMu4uSI/FEWk2bFNyJK0mUMf3gQlfpUKTC', 'boarder',  '2024-04-01 14:00:00'),
(7, 'mark_reyes',     '$2a$10$gZfol5NlmLAbcDgOXXrLMu4uSI/FEWk2bFNyJK0mUMf3gQlfpUKTC', 'boarder',  '2024-05-12 16:45:00')
ON DUPLICATE KEY UPDATE username=VALUES(username), password_hash=VALUES(password_hash), role=VALUES(role);

-- ─── 2. Mock Boarders ────────────────────────────────────────────────────────
INSERT INTO boarders (id, user_id, name, room, floor, phone, email, join_date, monthly_rate, due_day, grace_period_days, late_penalty_type, late_penalty_amount, emergency_name, emergency_relationship, emergency_phone, job) VALUES
(1, 3, 'Juan Dela Cruz',  '101', '1st', '09171234567', 'juan.cruz@example.com',   '2024-01-15', 3500.00, 10, 3, 'flat',       200.00, 'Pedro Dela Cruz',   'Father',  '09179876543', 'Software Developer'),
(2, 4, 'Maria Santos',    '102', '1st', '09182345678', 'maria.santos@example.com', '2024-02-01', 3800.00, 5,  3, 'percentage',   5.00, 'Elena Santos',     'Mother',  '09188765432', 'College Student'),
(3, 5, 'Alex Gonzales',   '201', '2nd', '09193456789', 'alex.gonzales@example.com','2024-03-10', 4000.00, 10, 5, 'flat',       250.00, 'Roberto Gonzales', 'Brother', '09197654321', 'Accountant'),
(4, 6, 'Sarah Geronimo',  '202', '2nd', '09204567890', 'sarah.g@example.com',      '2024-04-01', 3500.00, 15, 3, 'flat',       200.00, 'Divine Geronimo',  'Mother',  '09206543210', 'Graphic Designer'),
(5, 7, 'Mark Reyes',      '301', '3rd', '09215678901', 'mark.reyes@example.com',   '2024-05-12', 4200.00, 10, 3, 'percentage',  10.00, 'Clara Reyes',      'Spouse',  '09215432109', 'Civil Engineer')
ON DUPLICATE KEY UPDATE name=VALUES(name), room=VALUES(room), floor=VALUES(floor), phone=VALUES(phone), email=VALUES(email), monthly_rate=VALUES(monthly_rate);

-- ─── 3. Mock Payment Records ─────────────────────────────────────────────────
INSERT INTO payment_records (id, boarder_id, period, amount, paid_date, method, status, receipt_status, receipt_file, rejection_reason, recorded_by, verified_at, verified_by, notes) VALUES
(1, 1, '2026-07', 3500.00, '2026-07-08', 'gcash',         'paid',    'verified',       'receipts/juan_2026_07.jpg', NULL,                              'boarder',  '2026-07-09 10:00:00', 1, 'Paid via GCash Ref: 1002349182'),
(2, 1, '2026-08', 3500.00, '2026-08-09', 'gcash',         'paid',    'verified',       'receipts/juan_2026_08.jpg', NULL,                              'boarder',  '2026-08-10 11:30:00', 1, 'Paid early via GCash Ref: 1009841203'),
(3, 1, '2026-09', 3500.00, NULL,         NULL,            'pending', NULL,             NULL,                        NULL,                              NULL,       NULL,                  NULL, 'Rent due on Sept 10'),
(4, 2, '2026-08', 3800.00, '2026-08-04', 'bank_transfer', 'paid',    'verified',       'receipts/maria_2026_08.png',NULL,                              'boarder',  '2026-08-05 09:15:00', 1, 'BPI Online Transfer Ref: 8812903'),
(5, 2, '2026-09', 3800.00, '2026-09-06', 'gcash',         'pending', 'pending_review', 'receipts/maria_2026_09.png',NULL,                              'boarder',  NULL,                  NULL, 'Uploaded receipt, awaiting verification'),
(6, 3, '2026-07', 4000.00, '2026-07-10', 'cash',          'paid',    'verified',       NULL,                        NULL,                              'guardian', '2026-07-10 16:00:00', 1, 'Handed cash directly to landlord'),
(7, 3, '2026-08', 4250.00, NULL,         NULL,            'overdue', NULL,             NULL,                        NULL,                              NULL,       NULL,                  NULL, 'Includes 250 late penalty'),
(8, 4, '2026-08', 3500.00, '2026-08-14', 'gcash',         'paid',    'verified',       'receipts/sarah_2026_08.jpg',NULL,                              'boarder',  '2026-08-15 08:45:00', 2, 'GCash Ref: 981240192'),
(9, 4, '2026-09', 3500.00, NULL,         NULL,            'pending', NULL,             NULL,                        NULL,                              NULL,       NULL,                  NULL, 'Due on Sept 15'),
(10, 5, '2026-08', 4200.00, '2026-08-08', 'online',        'paid',    'verified',       'receipts/mark_2026_08.pdf', NULL,                              'boarder',  '2026-08-08 14:20:00', 1, 'Online bank transfer')
ON DUPLICATE KEY UPDATE amount=VALUES(amount), status=VALUES(status), receipt_status=VALUES(receipt_status);

-- ─── 4. Mock Attendance Sessions ──────────────────────────────────────────────
INSERT INTO attendance_sessions (id, type, date, window_start, window_end, qr_validity_mins) VALUES
(1, 'evening', '2026-09-07', '21:00:00', '22:00:00', 10),
(2, 'morning', '2026-09-08', '06:00:00', '07:30:00', 5),
(3, 'evening', '2026-09-08', '21:00:00', '22:00:00', 10),
(4, 'morning', '2026-09-09', '06:00:00', '07:30:00', 5)
ON DUPLICATE KEY UPDATE type=VALUES(type), date=VALUES(date);

-- ─── 5. Mock Attendance Records ───────────────────────────────────────────────
INSERT INTO attendance_records (id, boarder_id, session_id, status, check_in_time, method, override_reason, overridden_by) VALUES
(1,  1, 1, 'present', '2026-09-07 21:12:00', 'qr',     NULL,                 NULL),
(2,  2, 1, 'present', '2026-09-07 21:20:00', 'qr',     NULL,                 NULL),
(3,  3, 1, 'absent',  NULL,                  'qr',     NULL,                 NULL),
(4,  4, 1, 'present', '2026-09-07 21:40:00', 'qr',     NULL,                 NULL),
(5,  5, 1, 'present', '2026-09-07 21:15:00', 'qr',     NULL,                 NULL),
(6,  1, 2, 'present', '2026-09-08 06:15:00', 'qr',     NULL,                 NULL),
(7,  2, 2, 'present', '2026-09-08 06:45:00', 'qr',     NULL,                 NULL),
(8,  3, 2, 'present', '2026-09-08 07:10:00', 'qr',     NULL,                 NULL),
(9,  4, 2, 'present', '2026-09-08 06:50:00', 'qr',     NULL,                 NULL),
(10, 5, 2, 'present', '2026-09-08 06:20:00', 'qr',     NULL,                 NULL),
(11, 1, 3, 'present', '2026-09-08 21:05:00', 'qr',     NULL,                 NULL),
(12, 2, 3, 'present', '2026-09-08 21:10:00', 'manual', 'Phone battery died', 1),
(13, 3, 3, 'absent',  NULL,                  'qr',     NULL,                 NULL),
(14, 4, 3, 'present', '2026-09-08 21:30:00', 'qr',     NULL,                 NULL),
(15, 5, 3, 'present', '2026-09-08 21:25:00', 'qr',     NULL,                 NULL),
(16, 1, 4, 'present', '2026-09-09 06:22:00', 'qr',     NULL,                 NULL),
(17, 2, 4, 'present', '2026-09-09 06:30:00', 'qr',     NULL,                 NULL),
(18, 3, 4, 'absent',  NULL,                  'qr',     NULL,                 NULL),
(19, 4, 4, 'present', '2026-09-09 06:40:00', 'qr',     NULL,                 NULL),
(20, 5, 4, 'present', '2026-09-09 06:18:00', 'qr',     NULL,                 NULL)
ON DUPLICATE KEY UPDATE status=VALUES(status), check_in_time=VALUES(check_in_time);

-- ─── 6. Mock Announcements ───────────────────────────────────────────────────
INSERT INTO announcements (id, title, body, priority, recipients, sent_at, sent_by) VALUES
(1, 'Monthly Water Tank Cleaning', 'Please be informed that water tank maintenance will take place on Saturday from 8:00 AM to 12:00 PM. Water supply will be temporarily interrupted.', 'normal', '"all"', '2026-09-01 09:00:00', 1),
(2, 'Curfew Enforcement & Gate Lock Timing', 'Reminder to all boarders: Main gate will be locked strictly at 10:00 PM every night. Late arrivals must report to the guardian.', 'critical', '"all"', '2026-09-05 14:30:00', 1),
(3, 'Air Conditioner Maintenance - 2nd Floor', 'Technicians will inspect and clean AC units on the 2nd floor this Friday afternoon. Please keep your rooms accessible.', 'normal', '[3, 4]', '2026-09-07 11:00:00', 2)
ON DUPLICATE KEY UPDATE title=VALUES(title), body=VALUES(body);

-- ─── 7. Mock Visitor Entries ─────────────────────────────────────────────────
INSERT INTO visitor_entries (id, visitor_name, boarder_id, purpose, time_in, time_out, date) VALUES
(1, 'Carlos Dela Cruz', 1, 'Family visit / Bringing supplies', '2026-09-05 13:00:00', '2026-09-05 16:30:00', '2026-09-05'),
(2, 'Liza Soberano',     2, 'Group study session',          '2026-09-06 14:00:00', '2026-09-06 18:00:00', '2026-09-06'),
(3, 'David Licauco',    3, 'Delivering documents',         '2026-09-08 10:15:00', '2026-09-08 11:00:00', '2026-09-08'),
(4, 'Anna Reyes',       5, 'Visiting sibling',             '2026-09-09 09:30:00', NULL,                  '2026-09-09')
ON DUPLICATE KEY UPDATE visitor_name=VALUES(visitor_name), purpose=VALUES(purpose);

-- ─── 8. Mock Incidents ───────────────────────────────────────────────────────
INSERT INTO incidents (id, type, boarder_id, title, description, timestamp, resolved) VALUES
(1, 'missed_curfew', 3, 'Missed Evening Curfew', 'Boarder Alex Gonzales failed to check in before 10:00 PM curfew without prior notification.', '2026-09-07 22:15:00', 1),
(2, 'sos',           2, 'Emergency SOS Alert',   'Boarder triggered emergency alarm due to sudden fever and medical distress.',            '2026-09-06 02:45:00', 1),
(3, 'maintenance',   4, 'Water Leakage in Bathroom', 'Bathroom faucet in Room 202 is leaking heavily.',                                     '2026-09-08 15:20:00', 0)
ON DUPLICATE KEY UPDATE title=VALUES(title), description=VALUES(description), resolved=VALUES(resolved);

-- ─── 9. Mock Maintenance Reports ─────────────────────────────────────────────
INSERT INTO maintenance_reports (id, boarder_id, room, category, description, status, submitted_at, resolved_at) VALUES
(1, 1, '101', 'electrical', 'Ceiling fan speed controller not responding.',  'resolved',    '2026-08-20 10:00:00', '2026-08-21 14:00:00'),
(2, 4, '202', 'plumbing',   'Bathroom faucet leak needs washer replacement.','in_progress', '2026-09-08 15:20:00', NULL),
(3, 3, '201', 'furniture',  'Study desk chair wheel is broken.',             'open',        '2026-09-09 07:45:00', NULL)
ON DUPLICATE KEY UPDATE status=VALUES(status), description=VALUES(description);

-- ─── 10. Mock Curfew Records ──────────────────────────────────────────────────
INSERT INTO curfew_records (id, boarder_id, date, curfew_time, checked_in_at, status) VALUES
(1,  1, '2026-09-07', '22:00:00', '2026-09-07 21:30:00', 'compliant'),
(2,  2, '2026-09-07', '22:00:00', '2026-09-07 21:45:00', 'compliant'),
(3,  3, '2026-09-07', '22:00:00', NULL,                  'absent'),
(4,  4, '2026-09-07', '22:00:00', '2026-09-07 21:50:00', 'compliant'),
(5,  5, '2026-09-07', '22:00:00', '2026-09-07 21:15:00', 'compliant'),
(6,  1, '2026-09-08', '22:00:00', '2026-09-08 21:20:00', 'compliant'),
(7,  2, '2026-09-08', '22:00:00', '2026-09-08 21:40:00', 'compliant'),
(8,  3, '2026-09-08', '22:00:00', '2026-09-08 22:25:00', 'late'),
(9,  4, '2026-09-08', '22:00:00', '2026-09-08 21:55:00', 'compliant'),
(10, 5, '2026-09-08', '22:00:00', '2026-09-08 21:10:00', 'compliant')
ON DUPLICATE KEY UPDATE status=VALUES(status), checked_in_at=VALUES(checked_in_at);

SET FOREIGN_KEY_CHECKS = 1;
