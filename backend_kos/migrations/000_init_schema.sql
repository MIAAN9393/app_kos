-- Baseline schema for app_kos production database.
-- Target: MySQL 8.x / Railway MySQL.
--
-- Intended use:
--   - Run once on an empty database.
--   - Keep backend DB_SYNC=false in production.
--   - Do not run sequelize.sync(), force:true, or alter:true in production.
--
-- This file is intentionally a full baseline, not an incremental migration.

SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  email VARCHAR(100) NULL,
  email_verified TINYINT(1) NOT NULL DEFAULT 0,
  email_verified_at DATETIME NULL,
  no_telpon VARCHAR(20) NULL,
  phone_verified TINYINT(1) NOT NULL DEFAULT 0,
  phone_verified_at DATETIME NULL,
  password VARCHAR(255) NULL,
  google_id VARCHAR(100) NULL,
  foto_url TEXT NULL,
  refresh_token TEXT NULL,
  role ENUM('pemilik','admin') DEFAULT 'pemilik',
  status ENUM('aktif','nonaktif','diblokir') DEFAULT 'aktif',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uniq_users_email (email),
  UNIQUE KEY uniq_users_no_telpon (no_telpon),
  UNIQUE KEY uniq_users_google_id (google_id),
  INDEX idx_users_status (status),
  INDEX idx_users_role_status (role, status),
  INDEX idx_users_refresh_token (refresh_token(191))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE auth_otps (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  email VARCHAR(100) NULL,
  no_telpon VARCHAR(20) NULL,
  channel ENUM('email','phone') NOT NULL DEFAULT 'email',
  purpose ENUM('email_verification','phone_verification','password_reset') NOT NULL,
  code_hash VARCHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  attempt_count INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_auth_otps_user_purpose (user_id, purpose, used_at),
  INDEX idx_auth_otps_email_purpose (email, purpose, used_at),
  INDEX idx_auth_otps_phone_purpose (no_telpon, purpose, used_at),
  INDEX idx_auth_otps_expires_at (expires_at),
  CONSTRAINT fk_auth_otps_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE kos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pemilik_id INT NOT NULL,
  nama_kos VARCHAR(255) NOT NULL,
  alamat TEXT NULL,
  deskripsi TEXT NULL,
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_kos_pemilik_status (pemilik_id, status),
  INDEX idx_kos_status (status),
  CONSTRAINT fk_kos_pemilik
    FOREIGN KEY (pemilik_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE kamar (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kos_id INT NULL,
  nomor VARCHAR(20) NULL,
  harga BIGINT NULL,
  kapasitas INT UNSIGNED NULL,
  status_kondisi ENUM('kosong','sebagian','penuh') DEFAULT 'kosong',
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  fasilitas JSON NULL,

  INDEX idx_kamar_kos_status (kos_id, status),
  INDEX idx_kamar_status_kondisi (status_kondisi),
  CONSTRAINT fk_kamar_kos
    FOREIGN KEY (kos_id) REFERENCES kos(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE penyewa (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pemilik_id INT NOT NULL,
  nama VARCHAR(100) NOT NULL,
  tanggal_lahir DATE NULL,
  jenis_kelamin ENUM('pria','wanita') NULL,
  status_hubungan ENUM('jomblo','pacaran','menikah','duda','janda') NULL,
  no_telpon VARCHAR(20) NULL,
  email VARCHAR(100) NULL,
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  dibuat_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_penyewa_pemilik_status (pemilik_id, status),
  INDEX idx_penyewa_nama (nama),
  INDEX idx_penyewa_no_telpon (no_telpon),
  CONSTRAINT fk_penyewa_pemilik
    FOREIGN KEY (pemilik_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE kontrak (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kode_kontrak VARCHAR(50) NULL,
  public_token VARCHAR(100) NULL,
  penyewa_id INT NOT NULL,
  kamar_id INT NOT NULL,
  tanggal_mulai DATE NOT NULL,
  tanggal_selesai DATE NULL,
  harga_sewa BIGINT NOT NULL,
  siklus ENUM('tahunan','bulanan','mingguan','harian') DEFAULT 'bulanan',
  status ENUM('aktif','selesai','dibatalkan','pending') DEFAULT 'aktif',
  dibuat_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  diperbarui_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uniq_kontrak_kode (kode_kontrak),
  UNIQUE KEY uniq_kontrak_public_token (public_token),
  INDEX idx_kontrak_penyewa (penyewa_id),
  INDEX idx_kontrak_status (status),
  INDEX idx_kontrak_kamar_status (kamar_id, status),
  INDEX idx_kontrak_penyewa_status (penyewa_id, status),
  INDEX idx_kontrak_tanggal_mulai (tanggal_mulai),
  INDEX idx_kontrak_tanggal_selesai (tanggal_selesai),
  CONSTRAINT fk_kontrak_penyewa
    FOREIGN KEY (penyewa_id) REFERENCES penyewa(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_kontrak_kamar
    FOREIGN KEY (kamar_id) REFERENCES kamar(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tagihan (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kode_tagihan VARCHAR(50) NULL,
  public_token VARCHAR(100) NULL,
  kontrak_id INT NOT NULL,
  periode_awal DATE NOT NULL,
  periode_akhir DATE NOT NULL,
  jatuh_tempo DATE NOT NULL,
  total_tagihan BIGINT NOT NULL DEFAULT 0,
  lifecycle ENUM('draft','issued','cancelled') DEFAULT 'draft',
  status_pembayaran ENUM('belum_bayar','sebagian','lunas','telat') DEFAULT 'belum_bayar',
  catatan TEXT NULL,
  dibuat_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  diperbarui_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uniq_tagihan_kode (kode_tagihan),
  UNIQUE KEY uniq_tagihan_public_token (public_token),
  INDEX idx_tagihan_kontrak (kontrak_id),
  INDEX idx_tagihan_status (status_pembayaran),
  INDEX idx_tagihan_lifecycle (lifecycle),
  INDEX idx_tagihan_jatuh_tempo (jatuh_tempo),
  INDEX idx_tagihan_periode (periode_awal, periode_akhir),
  INDEX idx_tagihan_kontrak_periode (kontrak_id, periode_awal, periode_akhir),
  CONSTRAINT fk_tagihan_kontrak
    FOREIGN KEY (kontrak_id) REFERENCES kontrak(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tagihan_item (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tagihan_id INT NOT NULL,
  tipe ENUM('sewa','insiden','denda','diskon') NOT NULL,
  nama_item VARCHAR(100) NOT NULL,
  deskripsi VARCHAR(255) NULL,
  nominal BIGINT NOT NULL,
  event_date DATE NULL,
  dibuat_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_item_tagihan (tagihan_id),
  INDEX idx_item_tipe (tipe),
  CONSTRAINT fk_tagihan_item_tagihan
    FOREIGN KEY (tagihan_id) REFERENCES tagihan(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE pembayaran (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tagihan_id INT NOT NULL,
  jumlah_bayar BIGINT NOT NULL,
  status ENUM('valid','refund') DEFAULT 'valid',
  pembayaran_ref_id INT NULL,
  dibuat_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  dibatalkan_pada DATETIME NULL,

  INDEX idx_pembayaran_tagihan (tagihan_id),
  INDEX idx_pembayaran_ref (pembayaran_ref_id),
  INDEX idx_status_ref (status, pembayaran_ref_id),
  INDEX idx_pembayaran_dibuat_pada (dibuat_pada),
  CONSTRAINT fk_pembayaran_tagihan
    FOREIGN KEY (tagihan_id) REFERENCES tagihan(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_pembayaran_ref
    FOREIGN KEY (pembayaran_ref_id) REFERENCES pembayaran(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE whatsapp_integrations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  phone_number_id VARCHAR(255) NULL,
  access_token TEXT NULL,
  status ENUM('connected','disconnected') DEFAULT 'disconnected',

  UNIQUE KEY uniq_whatsapp_integration_user (user_id),
  CONSTRAINT fk_whatsapp_integrations_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE whatsapp_auto_send_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  auto_send_tagihan_on_create TINYINT(1) DEFAULT 0,
  auto_send_tagihan_from_cron TINYINT(1) DEFAULT 0,
  auto_send_tagihan_reminder_before_due TINYINT(1) DEFAULT 0,
  auto_send_tagihan_reminder_overdue TINYINT(1) DEFAULT 0,
  auto_send_penyewa_contract_on_create TINYINT(1) DEFAULT 0,
  auto_send_penyewa_contract_from_cron TINYINT(1) DEFAULT 0,
  auto_send_penyewa_reminder_before_contract_end TINYINT(1) DEFAULT 0,

  UNIQUE KEY uniq_whatsapp_auto_send_user (user_id),
  CONSTRAINT fk_whatsapp_auto_send_settings_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE whatsapp_message_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  tagihan_id INT NULL,
  kontrak_id INT NULL,
  penyewa_id INT NULL,
  no_tujuan VARCHAR(30) NOT NULL,
  tipe ENUM('test','invoice','kontrak','reminder') NOT NULL,
  status ENUM('pending','sent','failed') DEFAULT 'pending',
  wa_message_id VARCHAR(255) NULL,
  error_message TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_whatsapp_logs_user (user_id),
  INDEX idx_whatsapp_logs_tagihan (tagihan_id),
  INDEX idx_whatsapp_logs_kontrak (kontrak_id),
  INDEX idx_whatsapp_logs_penyewa (penyewa_id),
  INDEX idx_whatsapp_logs_tipe_status (tipe, status),
  CONSTRAINT fk_whatsapp_logs_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_whatsapp_logs_tagihan
    FOREIGN KEY (tagihan_id) REFERENCES tagihan(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_whatsapp_logs_kontrak
    FOREIGN KEY (kontrak_id) REFERENCES kontrak(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_whatsapp_logs_penyewa
    FOREIGN KEY (penyewa_id) REFERENCES penyewa(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE pengaturan_tagihan_otomatis (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kontrak_id INT NOT NULL,
  hari_sebelum_periode_mulai INT DEFAULT 0,
  jatuh_tempo_setelah_periode_mulai_hari INT DEFAULT 0,
  tanggal_proses_berikutnya DATE NULL,
  periode_awal_terakhir_dibuat DATE NULL,
  periode_akhir_terakhir_dibuat DATE NULL,
  tagihan_terakhir_id INT NULL,
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  dibuat_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  diperbarui_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uniq_pengaturan_tagihan_kontrak (kontrak_id),
  INDEX idx_proses_tagihan (tanggal_proses_berikutnya, status),
  INDEX idx_tagihan_terakhir (tagihan_terakhir_id),
  CONSTRAINT fk_pengaturan_tagihan_kontrak
    FOREIGN KEY (kontrak_id) REFERENCES kontrak(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_pengaturan_tagihan_terakhir
    FOREIGN KEY (tagihan_terakhir_id) REFERENCES tagihan(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE pengaturan_perpanjangan_kontrak_otomatis (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kontrak_awal_id INT NOT NULL,
  jenis_perpanjangan ENUM('tahunan','bulanan','mingguan','harian') DEFAULT 'bulanan',
  jumlah_periode_perpanjangan INT DEFAULT 1,
  hari_sebelum_berakhir INT DEFAULT 30,
  harga_perpanjangan BIGINT NULL,
  tanggal_proses_berikutnya DATE NULL,
  kontrak_terakhir_id INT NULL,
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  dibuat_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  diperbarui_pada DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uniq_pengaturan_perpanjangan_kontrak (kontrak_awal_id),
  INDEX idx_proses_perpanjangan (tanggal_proses_berikutnya, status),
  INDEX idx_perpanjangan_kontrak_terakhir (kontrak_terakhir_id),
  CONSTRAINT fk_pengaturan_perpanjangan_awal
    FOREIGN KEY (kontrak_awal_id) REFERENCES kontrak(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_pengaturan_perpanjangan_terakhir
    FOREIGN KEY (kontrak_terakhir_id) REFERENCES kontrak(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE fcm_tokens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  token TEXT NOT NULL,
  platform ENUM('android','ios','web') DEFAULT 'android',
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_fcm_tokens_user_status (user_id, status),
  INDEX idx_fcm_tokens_status_platform (status, platform),
  INDEX idx_fcm_tokens_token (token(191)),
  CONSTRAINT fk_fcm_tokens_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE fcm_notification_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  notif_tagihan_jatuh_tempo TINYINT(1) DEFAULT 1,
  notif_tagihan_telat TINYINT(1) DEFAULT 1,
  notif_tagihan_otomatis TINYINT(1) DEFAULT 1,
  notif_kontrak_akan_berakhir TINYINT(1) DEFAULT 1,
  notif_kontrak_selesai TINYINT(1) DEFAULT 1,
  notif_perpanjangan_otomatis TINYINT(1) DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uniq_fcm_notification_settings_user (user_id),
  CONSTRAINT fk_fcm_notification_settings_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE pembayaran_langganan (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  order_id VARCHAR(100) NOT NULL,
  paket VARCHAR(100) NOT NULL,
  jumlah BIGINT NOT NULL,
  status ENUM('pending','settlement','capture','expire','cancel','deny','failure') NOT NULL DEFAULT 'pending',
  snap_token TEXT NULL,
  redirect_url TEXT NULL,
  payment_type VARCHAR(50) NULL,
  fraud_status VARCHAR(50) NULL,
  raw_response JSON NULL,
  paid_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY idx_pembayaran_langganan_order (order_id),
  INDEX idx_pembayaran_langganan_user (user_id),
  INDEX idx_pembayaran_langganan_status (status),
  INDEX idx_pembayaran_langganan_paid_at (paid_at),
  CONSTRAINT fk_pembayaran_langganan_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE user_subscriptions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  paket ENUM('free','starter','pro') NOT NULL DEFAULT 'free',
  status ENUM('active','past_due','expired','cancelled') NOT NULL DEFAULT 'active',
  source_payment_id INT NULL,
  started_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expired_at DATETIME NULL,
  grace_until DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_user_subscriptions_user_status (user_id, status),
  INDEX idx_user_subscriptions_expired_at (expired_at),
  INDEX idx_user_subscriptions_grace_until (grace_until),
  INDEX idx_user_subscriptions_source_payment (source_payment_id),
  CONSTRAINT fk_user_subscriptions_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_user_subscriptions_payment
    FOREIGN KEY (source_payment_id) REFERENCES pembayaran_langganan(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
