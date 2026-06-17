ALTER TABLE users
  MODIFY COLUMN email VARCHAR(100) NULL,
  ADD COLUMN no_telpon VARCHAR(20) NULL UNIQUE AFTER email_verified_at,
  ADD COLUMN phone_verified TINYINT(1) NOT NULL DEFAULT 0 AFTER no_telpon,
  ADD COLUMN phone_verified_at TIMESTAMP NULL AFTER phone_verified;

ALTER TABLE auth_otps
  MODIFY COLUMN email VARCHAR(100) NULL,
  ADD COLUMN no_telpon VARCHAR(20) NULL AFTER email,
  ADD COLUMN channel ENUM('email','phone') NOT NULL DEFAULT 'email' AFTER no_telpon,
  MODIFY COLUMN purpose ENUM('email_verification','phone_verification','password_reset') NOT NULL;

CREATE INDEX idx_auth_otps_phone_purpose ON auth_otps (no_telpon, purpose, used_at);
