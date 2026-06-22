CREATE TABLE IF NOT EXISTS user_subscriptions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  paket ENUM('free', 'starter', 'pro') NOT NULL DEFAULT 'free',
  status ENUM('active', 'expired', 'cancelled') NOT NULL DEFAULT 'active',
  source_payment_id INT NULL,
  started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expired_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_subscriptions_user_status (user_id, status),
  INDEX idx_user_subscriptions_expired_at (expired_at),
  CONSTRAINT fk_user_subscriptions_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_user_subscriptions_payment
    FOREIGN KEY (source_payment_id) REFERENCES pembayaran_langganan(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);
