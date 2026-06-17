ALTER TABLE users
  ADD COLUMN email_verified TINYINT(1) NOT NULL DEFAULT 0 AFTER email,
  ADD COLUMN email_verified_at TIMESTAMP NULL AFTER email_verified;

-- Anggap akun lama sudah terverifikasi agar login existing tidak terganggu.
UPDATE users SET email_verified = 1, email_verified_at = COALESCE(email_verified_at, created_at);

CREATE TABLE auth_otps (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  email VARCHAR(100) NOT NULL,
  purpose ENUM('email_verification','password_reset') NOT NULL,
  code_hash VARCHAR(64) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP NULL,
  attempt_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_auth_otps_user_purpose (user_id, purpose, used_at),
  INDEX idx_auth_otps_email_purpose (email, purpose, used_at),
  INDEX idx_auth_otps_expires_at (expires_at)
) ENGINE=InnoDB;
