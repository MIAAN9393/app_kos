const { Op } = require("sequelize")
const Kamar = require("../model/kamar")
const Kos = require("../model/kos")
const Kontrak = require("../model/kontrak")
const { throwError } = require("./error")
const { hitungTotalDibayar, hitungSisaTagihan } = require("./tagihan_helper")

/**
 * Parse string bulan YYYY-MM menjadi { tahun, bulan }.
 * Dipakai query laporan rentang waktu.
 */
exports.parseBulan = (str) => {
  const parts = String(str).trim().split("-")
  if (parts.length !== 2) return null
  const tahun = Number(parts[0])
  const bulan = Number(parts[1])
  if (!tahun || bulan < 1 || bulan > 12) return null
  return { tahun, bulan }
}

/**
 * Ubah YYYY-MM jadi tanggal awal & akhir (inklusif) untuk filter SQL DATE.
 * Contoh: 2026-02 .. 2026-03 → 2026-02-01 s/d 2026-03-31
 */
exports.rentangTanggalDariBulan = (bulan_mulai, bulan_akhir) => {
  const mulai = exports.parseBulan(bulan_mulai)
  const akhir = exports.parseBulan(bulan_akhir)

  if (!mulai || !akhir) {
    throwError("format bulan harus YYYY-MM", 400, "BULAN_FORMAT_INVALID")
  }

  const awal_key = mulai.tahun * 12 + mulai.bulan
  const akhir_key = akhir.tahun * 12 + akhir.bulan

  if (awal_key > akhir_key) {
    throwError(
      "bulan_mulai tidak boleh lebih besar dari bulan_akhir",
      400,
      "BULAN_RANGE_INVALID"
    )
  }

  const tanggal_awal = `${mulai.tahun}-${String(mulai.bulan).padStart(2, "0")}-01`

  const hari_terakhir = new Date(akhir.tahun, akhir.bulan, 0).getDate()
  const tanggal_akhir = `${akhir.tahun}-${String(akhir.bulan).padStart(2, "0")}-${String(hari_terakhir).padStart(2, "0")}`

  return { tanggal_awal, tanggal_akhir, bulan_mulai, bulan_akhir }
}

/**
 * Label periode untuk response UI.
 */
exports.labelPeriode = (bulan_mulai, bulan_akhir) => {
  if (bulan_mulai === bulan_akhir) return bulan_mulai
  return `${bulan_mulai} – ${bulan_akhir}`
}

/**
 * Ambil semua kontrak_id milik pemilik (opsional filter satu kos).
 * Semua laporan di-scope ke properti pemilik login.
 */
exports.ambil_kontrak_ids_pemilik = async (pemilik_id, kos_ids = null) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  const kos_where = {
    pemilik_id,
    status: "aktif",
  }

  // Multi-filter kos dari frontend (kos_ids=1,2,3)
  if (kos_ids && kos_ids.length > 0) {
    kos_where.id = { [Op.in]: kos_ids }
  }

  const kontrak_rows = await Kontrak.findAll({
    attributes: ["id"],
    include: [
      {
        model: Kamar,
        required: true,
        attributes: [],
        include: [
          {
            model: Kos,
            required: true,
            attributes: [],
            where: kos_where,
          },
        ],
      },
    ],
    raw: true,
  })

  return kontrak_rows.map((r) => r.id)
}

/**
 * Agregat jumlah & nominal tagihan per status_pembayaran.
 * Status mengikuti DB: belum_bayar, sebagian, lunas, telat.
 * Nominal = total tagihan (tanpa pembayaran).
 */
exports.agregatTagihanPerStatus = (rows = []) => {
  return exports.agregatTagihanPerStatusDenganSisa(rows, {})
}

/**
 * Agregat tagihan per status; nominal = sisa aktual kecuali lunas (nominal penuh).
 */
exports.agregatTagihanPerStatusDenganSisa = (
  rows = [],
  pembayaran_per_tagihan = {}
) => {
  const kosong = () => ({ jumlah: 0, nominal: 0 })

  const hasil = {
    lunas: kosong(),
    sebagian: kosong(),
    belum_bayar: kosong(),
    telat: kosong(),
  }

  let total_jumlah = 0
  let total_nominal = 0

  for (const row of rows) {
    const status = row.status_pembayaran
    if (!hasil[status]) continue

    const id = Number(row.id)
    const total = Number(row.total_tagihan) || 0
    const dibayar = hitungTotalDibayar(pembayaran_per_tagihan[id] || [])
    const sisa = Math.max(0, hitungSisaTagihan(total, dibayar))
    const nominal = status === "lunas" ? total : sisa

    hasil[status].jumlah += 1
    hasil[status].nominal += nominal
    total_jumlah += 1
    total_nominal += nominal
  }

  return {
    total_tagihan: total_jumlah,
    total_nominal_tagihan: total_nominal,
    per_status: hasil,
  }
}

/**
 * Agregat pembayaran valid & refund dalam rentang tanggal_bayar.
 * Catatan: kolom DB `dibuat_pada` dipakai sebagai tanggal_bayar (uang diterima).
 */
exports.agregatPembayaran = (rows = []) => {
  const hasil = {
    valid: { jumlah: 0, nominal: 0 },
    refund: { jumlah: 0, nominal: 0 },
  }

  for (const row of rows) {
    const nominal = Number(row.jumlah_bayar) || 0
    if (row.status === "valid") {
      hasil.valid.jumlah += 1
      hasil.valid.nominal += nominal
    }
    if (row.status === "refund") {
      hasil.refund.jumlah += 1
      hasil.refund.nominal += nominal
    }
  }

  const total_pembayaran = hasil.valid.jumlah + hasil.refund.jumlah

  return {
    total_pembayaran,
    total_uang_masuk: hasil.valid.nominal,
    total_refund: hasil.refund.nominal,
    per_status: hasil,
  }
}

/**
 * Kelompokkan baris pembayaran per tagihan_id.
 */
exports.kelompokkanPembayaranPerTagihan = (pembayaran_rows = []) => {
  const map = {}
  for (const row of pembayaran_rows) {
    const id = Number(row.tagihan_id)
    if (!map[id]) map[id] = []
    map[id].push(row)
  }
  return map
}

/**
 * Total nominal penuh tagihan (tanpa pengurangan pembayaran).
 */
exports.hitungTotalNominalPenuh = (rows = []) => {
  return rows.reduce(
    (sum, row) => sum + (Number(row.total_tagihan) || 0),
    0
  )
}

/**
 * Total piutang = jumlah sisa aktual (total_tagihan − pembayaran net), semua tagihan issued.
 */
exports.hitungTotalPiutang = (tagihan_rows = [], pembayaran_per_tagihan = {}) => {
  let total = 0
  for (const row of tagihan_rows) {
    const id = Number(row.id)
    const nominal = Number(row.total_tagihan) || 0
    const dibayar = hitungTotalDibayar(pembayaran_per_tagihan[id] || [])
    const sisa = Math.max(0, hitungSisaTagihan(nominal, dibayar))
    total += sisa
  }
  return total
}
