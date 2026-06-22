-- 1. USERS
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NULL,
    email_verified TINYINT(1) NOT NULL DEFAULT 0,
    email_verified_at TIMESTAMP NULL,
    no_telpon VARCHAR(20) UNIQUE NULL,
    phone_verified TINYINT(1) NOT NULL DEFAULT 0,
    phone_verified_at TIMESTAMP NULL,
    password VARCHAR(255) NULL,
    google_id VARCHAR(100) UNIQUE NULL,
    foto_url TEXT NULL,
    refresh_token TEXT NULL,
    role ENUM('pemilik', 'admin') DEFAULT 'pemilik',
    status ENUM('aktif','nonaktif','diblokir') DEFAULT 'aktif',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE auth_otps (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  email VARCHAR(100) NULL,
  no_telpon VARCHAR(20) NULL,
  channel ENUM('email','phone') NOT NULL DEFAULT 'email',
  purpose ENUM('email_verification','phone_verification','password_reset') NOT NULL,
  code_hash VARCHAR(64) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  used_at TIMESTAMP NULL,
  attempt_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_auth_otps_user_purpose (user_id, purpose, used_at),
  INDEX idx_auth_otps_email_purpose (email, purpose, used_at),
  INDEX idx_auth_otps_phone_purpose (no_telpon, purpose, used_at),
  INDEX idx_auth_otps_expires_at (expires_at)
) ENGINE=InnoDB;

-- 2. KOS
CREATE TABLE kos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pemilik_id INT NOT NULL,
  nama_kos VARCHAR(150) NOT NULL,
  alamat TEXT,
  deskripsi TEXT,
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (pemilik_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- 3. KAMAR
CREATE TABLE kamar (
  id INT AUTO_INCREMENT PRIMARY KEY,
  -- pemilik_id INT,
  kos_id INT,
  nomor VARCHAR(20),
  harga BIGINT,
  kapasitas INT UNSIGNED,
  status_kondisi ENUM('kosong','sebagian','penuh') DEFAULT 'kosong',
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  fasilitas JSON NULL,

  -- FOREIGN KEY (pemilik_id) REFERENCES users(id),
  FOREIGN KEY (kos_id) REFERENCES kos(id)
) ENGINE=InnoDB;

-- 4. PENYEWA
CREATE TABLE penyewa (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pemilik_id INT NOT NULL,
  nama VARCHAR(100) NOT NULL,
  tanggal_lahir DATE NULL,
  jenis_kelamin ENUM('pria','wanita') NULL,
  status_hubungan ENUM('jomblo','pacaran','menikah','duda','janda') NULL,
  
  no_telpon VARCHAR(20),
  email VARCHAR(100),
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (pemilik_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- 5. KONTRAK
CREATE TABLE kontrak (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kode_kontrak VARCHAR(50) UNIQUE,
    public_token VARCHAR(100) UNIQUE NULL,

    penyewa_id INT NOT NULL,
    kamar_id INT NOT NULL,

    tanggal_mulai DATE NOT NULL,
    tanggal_selesai DATE NULL,

    harga_sewa BIGINT NOT NULL,
    siklus ENUM('tahunan','bulanan','mingguan','harian') DEFAULT 'bulanan',

    status ENUM('aktif','selesai','dibatalkan','pending') DEFAULT 'aktif',

    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diperbarui_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (penyewa_id) REFERENCES penyewa(id) ON DELETE RESTRICT,
    FOREIGN KEY (kamar_id) REFERENCES kamar(id) ON DELETE RESTRICT,

    INDEX idx_kontrak_penyewa (penyewa_id),
    INDEX idx_kontrak_status (status),
    INDEX idx_kontrak_kamar_status (kamar_id, status),
    INDEX idx_kontrak_penyewa_status (penyewa_id, status)
) ENGINE=InnoDB;

-- 6. TAGIHAN
CREATE TABLE tagihan (
    id INT AUTO_INCREMENT PRIMARY KEY,

    kode_tagihan VARCHAR(50) UNIQUE,
    public_token VARCHAR(100) UNIQUE NULL,

    kontrak_id INT NOT NULL,

    periode_awal DATE NOT NULL,
    periode_akhir DATE NOT NULL,

    jatuh_tempo DATE NOT NULL,
    total_tagihan BIGINT NOT NULL DEFAULT 0,

    lifecycle ENUM('draft','issued','cancelled')
        DEFAULT 'draft',

    status_pembayaran ENUM(
        'belum_bayar',
        'sebagian',
        'lunas',
        'telat'
    ) DEFAULT 'belum_bayar',

    catatan TEXT,

    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    diperbarui_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (kontrak_id) REFERENCES kontrak(id),

    -- UNIQUE (kontrak_id, periode_awal, periode_akhir),

    INDEX idx_tagihan_kontrak (kontrak_id),
    INDEX idx_tagihan_status (status_pembayaran),
    INDEX idx_tagihan_lifecycle (lifecycle),
    INDEX idx_tagihan_jatuh_tempo (jatuh_tempo)

) ENGINE=InnoDB;

--8. TAGIHAN ITEM
CREATE TABLE tagihan_item (
    id INT AUTO_INCREMENT PRIMARY KEY,

    tagihan_id INT NOT NULL,

    tipe ENUM('sewa','insiden','denda','diskon') NOT NULL,

    nama_item VARCHAR(100) NOT NULL,
    deskripsi VARCHAR(255),

    nominal BIGINT NOT NULL,

    event_date DATE NULL,

    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tagihan_id) REFERENCES tagihan(id),

    INDEX idx_item_tagihan (tagihan_id),
    INDEX idx_item_tipe (tipe)
) ENGINE=InnoDB;

-- 9. PEMBAYARAN (ledger style)
CREATE TABLE pembayaran (
  id INT AUTO_INCREMENT PRIMARY KEY,

  tagihan_id INT NOT NULL,
  jumlah_bayar BIGINT NOT NULL,

  status ENUM('valid','refund') DEFAULT 'valid',

  pembayaran_ref_id INT NULL,

  dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  dibatalkan_pada TIMESTAMP NULL,

  FOREIGN KEY (tagihan_id) REFERENCES tagihan(id),

  CONSTRAINT fk_pembayaran_ref
  FOREIGN KEY (pembayaran_ref_id) REFERENCES pembayaran(id),

  INDEX idx_pembayaran_tagihan (tagihan_id),
  INDEX idx_pembayaran_ref (pembayaran_ref_id),
  INDEX idx_status_ref (status, pembayaran_ref_id)

) ENGINE=InnoDB;

CREATE TABLE whatsapp_integrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    phone_number_id VARCHAR(255),
    access_token TEXT,
    status ENUM('connected','disconnected') DEFAULT 'disconnected',

    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE KEY uniq_whatsapp_integration_user (user_id)
) ENGINE=InnoDB;

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

    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE KEY uniq_whatsapp_auto_send_user (user_id)
) ENGINE=InnoDB;

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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (tagihan_id) REFERENCES tagihan(id),
    FOREIGN KEY (kontrak_id) REFERENCES kontrak(id),
    FOREIGN KEY (penyewa_id) REFERENCES penyewa(id),

    INDEX idx_whatsapp_logs_user (user_id),
    INDEX idx_whatsapp_logs_tagihan (tagihan_id),
    INDEX idx_whatsapp_logs_kontrak (kontrak_id),
    INDEX idx_whatsapp_logs_penyewa (penyewa_id),
    INDEX idx_whatsapp_logs_tipe_status (tipe, status)
) ENGINE=InnoDB;

CREATE TABLE pengaturan_perpanjangan_kontrak_otomatis (
    id INT AUTO_INCREMENT PRIMARY KEY,

    kontrak_awal_id INT NOT NULL,

    jenis_perpanjangan ENUM(
        'tahunan',
        'bulanan',
        'mingguan',
        'harian'
    ) DEFAULT 'bulanan',

    jumlah_periode_perpanjangan INT DEFAULT 1,

    hari_sebelum_berakhir INT DEFAULT 30,

    harga_perpanjangan BIGINT NULL,

    tanggal_proses_berikutnya DATE NULL,

    kontrak_terakhir_id INT NULL,

    status ENUM('aktif','nonaktif') DEFAULT 'aktif',

    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    diperbarui_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (kontrak_awal_id) REFERENCES kontrak(id),

    FOREIGN KEY (kontrak_terakhir_id) REFERENCES kontrak(id),

    UNIQUE KEY uniq_pengaturan_perpanjangan_kontrak (kontrak_awal_id),

    INDEX idx_proses_perpanjangan
        (tanggal_proses_berikutnya, status)
) ENGINE=InnoDB;


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

    dibuat_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    diperbarui_pada TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (kontrak_id)
        REFERENCES kontrak(id),

    FOREIGN KEY (tagihan_terakhir_id)
        REFERENCES tagihan(id),

    UNIQUE KEY uniq_pengaturan_tagihan_kontrak
        (kontrak_id),

    INDEX idx_proses_tagihan
        (tanggal_proses_berikutnya, status),

    INDEX idx_tagihan_terakhir
        (tagihan_terakhir_id)
) ENGINE=InnoDB;

CREATE TABLE fcm_tokens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  token TEXT NOT NULL,
  platform ENUM('android','ios','web') DEFAULT 'android',
  status ENUM('aktif','nonaktif') DEFAULT 'aktif',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (user_id) REFERENCES users(id)
);
