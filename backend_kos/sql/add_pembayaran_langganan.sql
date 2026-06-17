CREATE TABLE IF NOT EXISTS pembayaran_langganan (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  order_id VARCHAR(100) NOT NULL UNIQUE,
  paket VARCHAR(100) NOT NULL,
  jumlah BIGINT NOT NULL,
  status ENUM('pending', 'settlement', 'capture', 'expire', 'cancel', 'deny', 'failure') NOT NULL DEFAULT 'pending',
  snap_token TEXT NULL,
  redirect_url TEXT NULL,
  payment_type VARCHAR(50) NULL,
  fraud_status VARCHAR(50) NULL,
  raw_response JSON NULL,
  paid_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_pembayaran_langganan_user (user_id),
  INDEX idx_pembayaran_langganan_status (status),
  CONSTRAINT fk_pembayaran_langganan_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);
