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
