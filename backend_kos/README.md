# Sistem Manajemen Kos

## Deskripsi

Aplikasi manajemen kos untuk pemilik kos.

Backend menggunakan:

- Node.js
- Express
- Sequelize
- MySQL
- JWT Authentication

Frontend yang akan dibuat menggunakan Flutter.

---

# Tujuan Aplikasi

Pemilik kos dapat:

- Login
- Mengelola data kos
- Mengelola kamar
- Mengelola penyewa
- Membuat kontrak sewa
- Membuat tagihan
- Mencatat pembayaran

---

# Role

Saat ini hanya ada role:

- pemilik

Role admin sudah disiapkan di database tetapi belum digunakan.

---

# Struktur Domain

## 1. User (Pemilik)

Mewakili akun yang login ke sistem.

Field penting:

- id
- nama
- email
- role
- status

Relasi:

User
└── Banyak Kos
└── Banyak Penyewa

---

## 2. Kos

Mewakili satu lokasi kos.

Field penting:

- id
- pemilik_id
- nama_kos
- alamat
- deskripsi
- status

Relasi:

Kos
└── Banyak Kamar

---

## 3. Kamar

Mewakili kamar dalam kos.

Field penting:

- id
- kos_id
- nomor
- harga
- kapasitas

status_kondisi:

- kosong
- sebagian
- penuh

status:

- aktif
- nonaktif

Relasi:

Kamar
└── Banyak Kontrak

---

## 4. Penyewa

Mewakili orang yang menyewa kamar.

Field penting:

- id
- pemilik_id
- nama
- no_telpon
- email
- status

status:

- aktif
- nonaktif

Relasi:

Penyewa
└── Banyak Kontrak

Catatan:

Penyewa tidak langsung menempati kamar.

Hubungan penyewa dengan kamar dilakukan melalui kontrak.

---

## 5. Kontrak

Mewakili hubungan penyewa dengan kamar.

Field penting:

- id
- penyewa_id
- kamar_id
- tanggal_mulai
- tanggal_selesai
- harga_sewa
- siklus

siklus:

- harian
- mingguan
- bulanan

status:

- aktif
- selesai
- dibatalkan

Relasi:

Kontrak
└── Banyak Tagihan

Catatan:

Kontrak adalah pusat proses bisnis.

Semua tagihan dibuat berdasarkan kontrak.

---

## 6. Tagihan

Mewakili kewajiban pembayaran penyewa.

Field penting:

- id
- kode_tagihan
- kontrak_id
- periode_awal
- periode_akhir
- jatuh_tempo
- total_tagihan

lifecycle:

- draft
- issued
- cancelled

status_pembayaran:

- belum_bayar
- sebagian
- lunas
- telat

Relasi:

Tagihan
└── Banyak Pembayaran

---

## 7. Pembayaran

Mencatat transaksi pembayaran.

Field penting:

- id
- tagihan_id
- jumlah_bayar

status:

- valid
- refund

Relasi:

Pembayaran
└── Milik satu Tagihan

---

# Alur Bisnis Utama

## Alur 1 - Membuat Penyewa dan Kontrak

1. Pemilik membuka halaman penyewa.
2. Pemilik dapat:

   - memilih penyewa yang sudah ada

   atau

   - membuat penyewa baru

3. Pemilik memilih kamar.
4. Pemilik membuat kontrak.
5. Kontrak menjadi aktif.

Flow:

Penyewa
↓
Pilih Kamar
↓
Buat Kontrak
↓
Kontrak Aktif

---

## Alur 2 - Tagihan

Kontrak aktif dapat menghasilkan tagihan.

Flow:

Kontrak
↓
Tagihan
↓
Pembayaran

---

## Alur 3 - Pembayaran

1. Pemilik membuka detail tagihan.
2. Menambahkan pembayaran.
3. Status tagihan dihitung berdasarkan total pembayaran.

Contoh:

Total tagihan = 1.000.000

Bayar 500.000

Status:

sebagian

Bayar lagi 500.000

Status:

lunas

---

# Halaman Flutter yang Dibutuhkan

## Auth

- Login

---

## Dashboard

Menampilkan ringkasan:

- jumlah kos
- jumlah kamar
- jumlah penyewa aktif
- jumlah kontrak aktif
- jumlah tagihan belum lunas

---

## Kos

- Daftar kos
- Tambah kos
- Edit kos
- Detail kos

---

## Kamar

- Daftar kamar
- Tambah kamar
- Edit kamar
- Detail kamar

---

## Penyewa

- Daftar penyewa aktif
- Daftar penyewa nonaktif
- Detail penyewa
- Tambah penyewa
- Edit penyewa

---

## Kontrak

- Daftar kontrak
- Detail kontrak
- Buat kontrak

Fitur penting:

Saat membuat kontrak:

- Pilih penyewa yang sudah ada

atau

- Buat penyewa baru

Kemudian:

- Pilih kamar
- Isi data kontrak
- Simpan

---

## Tagihan

- Daftar tagihan
- Detail tagihan
- Buat tagihan

Filter:

- Belum bayar
- Sebagian
- Lunas
- Telat

---

## Pembayaran

- Daftar pembayaran
- Tambah pembayaran
- Riwayat pembayaran

---

# Standar Response API

Format umum:

```json
{
  "success": true,
  "code": "SUCCESS_CODE",
  "pesan": "pesan",
  "data": {}
}
```

Format error:

```json
{
  "success": false,
  "code": "ERROR_CODE",
  "pesan": "error message"
}
```

# Catatan Penting Untuk AI Frontend

- Gunakan Flutter.
- Gunakan clean architecture sederhana.
- Gunakan repository pattern.
- Gunakan DTO/model untuk parsing JSON.
- Simpan JWT access token.
- Semua endpoint selain login membutuhkan Authorization Bearer Token.
- Fokus pada UX CRUD yang cepat dan sederhana.
- Prioritas utama aplikasi adalah pengelolaan penyewa → kontrak → tagihan → pembayaran.