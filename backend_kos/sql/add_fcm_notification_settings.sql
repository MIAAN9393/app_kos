CREATE TABLE IF NOT EXISTS fcm_notification_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  notif_tagihan_jatuh_tempo TINYINT(1) DEFAULT 1,
  notif_tagihan_telat TINYINT(1) DEFAULT 1,
  notif_tagihan_otomatis TINYINT(1) DEFAULT 1,
  notif_kontrak_akan_berakhir TINYINT(1) DEFAULT 1,
  notif_kontrak_selesai TINYINT(1) DEFAULT 1,
  notif_perpanjangan_otomatis TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id),
  UNIQUE KEY uniq_fcm_notification_settings_user (user_id)
) ENGINE=InnoDB;
