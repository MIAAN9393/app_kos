require("../model/index")

const PDFDocument = require("pdfkit")
const Kontrak = require("../model/kontrak")
const Kamar = require("../model/kamar")
const Kos = require("../model/kos")
const Penyewa = require("../model/penyewa")
const { throwError } = require("../utils/error")

function formatRupiah(value) {
  const amount = Number(value) || 0
  return `Rp ${amount.toLocaleString("id-ID")}`
}

function formatTanggal(value) {
  if (!value) return "-"
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return String(value).split("T")[0] || "-"
  return date.toLocaleDateString("id-ID", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  })
}

function titleCase(value) {
  const raw = String(value || "-").replace(/_/g, " ").toLowerCase()
  if (raw === "-") return raw
  return raw
    .split(" ")
    .filter(Boolean)
    .map((part) => `${part[0].toUpperCase()}${part.slice(1)}`)
    .join(" ")
}

function safeFileName(value) {
  return String(value || "kontrak")
    .trim()
    .replace(/[^a-zA-Z0-9._-]+/g, "_")
    .replace(/^_+|_+$/g, "")
}

function header(doc, title, subtitle) {
  const startY = doc.y
  doc
    .roundedRect(doc.x, startY, 36, 36, 8)
    .fill("#2563EB")
    .fillColor("#FFFFFF")
    .font("Helvetica-Bold")
    .fontSize(12)
    .text("MK", doc.x, startY + 11, { width: 36, align: "center" })

  doc
    .fillColor("#111827")
    .font("Helvetica-Bold")
    .fontSize(20)
    .text(title, 96, startY + 1)

  if (String(subtitle || "").trim()) {
    doc
      .font("Helvetica")
      .fontSize(10)
      .fillColor("#6B7280")
      .text(subtitle, 96, startY + 26)
  }

  doc
    .moveTo(32, startY + 52)
    .lineTo(563, startY + 52)
    .strokeColor("#E5E7EB")
    .stroke()
  doc.y = startY + 68
}

function section(doc, title, drawContent) {
  const startX = 32
  const startY = doc.y
  const width = 531
  doc
    .roundedRect(startX, startY, width, 24, 8)
    .fillAndStroke("#F8FAFC", "#E5E7EB")
    .fillColor("#2563EB")
    .font("Helvetica-Bold")
    .fontSize(12)
    .text(title, startX + 12, startY + 12)

  doc.y = startY + 34
  drawContent(startX + 12, width - 24)
  const endY = doc.y + 5
  doc
    .roundedRect(startX, startY, width, Math.max(48, endY - startY), 8)
    .strokeColor("#E5E7EB")
    .stroke()
  doc.y = endY + 11
}

function infoRow(doc, label, value, x = 44, width = 507) {
  const y = doc.y
  doc
    .font("Helvetica")
    .fontSize(9)
    .fillColor("#6B7280")
    .text(label, x, y, { width: Math.floor(width * 0.4) })
    .font("Helvetica-Bold")
    .fontSize(10)
    .fillColor("#111827")
    .text(String(value ?? "-"), x + Math.floor(width * 0.4) + 8, y, {
      width: Math.floor(width * 0.6) - 8,
    })
  doc.y = Math.max(doc.y, y + 17)
}

function footer(doc, text) {
  doc
    .font("Helvetica")
    .fontSize(8)
    .fillColor("#6B7280")
    .text(text || "Dokumen ini dibuat otomatis melalui aplikasi Manajemen Kos.", 32, doc.y + 2)
}

function ambilRelasi(row, nama) {
  if (!row) return null
  if (row[nama]) return row[nama]
  if (typeof row.get === "function") return row.get(nama) || null
  return null
}

async function bentukKontrakData(kontrak, user_id = null) {
  const penyewa =
    ambilRelasi(kontrak, "Penyewa") ||
    (kontrak ? await Penyewa.findByPk(kontrak.penyewa_id) : null)
  const kamar =
    ambilRelasi(kontrak, "Kamar") ||
    (kontrak ? await Kamar.findByPk(kontrak.kamar_id) : null)
  const kos =
    ambilRelasi(kamar, "Kos") ||
    (kamar ? await Kos.findByPk(kamar.kos_id) : null)

  if (!penyewa || !kamar || !kos) {
    throwError(
      "Data relasi kontrak tidak lengkap untuk membuat PDF.",
      404,
      "KONTRAK_PDF_RELATION_NOT_FOUND"
    )
  }

  if (user_id && Number(kos.pemilik_id) !== Number(user_id)) {
    throwError(
      "Kontrak tidak ditemukan atau bukan milik user login.",
      404,
      "KONTRAK_NOT_FOUND"
    )
  }

  return {
    kontrak,
    penyewa,
    kamar,
    kos,
  }
}

async function loadKontrakData(kontrak_id, user_id) {
  const kontrak = await Kontrak.findOne({
    where: { id: kontrak_id },
  })

  if (!kontrak) {
    throwError(
      "Kontrak tidak ditemukan atau bukan milik user login.",
      404,
      "KONTRAK_NOT_FOUND"
    )
  }

  return bentukKontrakData(kontrak, user_id)
}

async function loadKontrakDataByPublicToken(kode_kontrak, public_token) {
  const kode = String(kode_kontrak || "").trim()
  const token = String(public_token || "").trim()
  if (!kode || !token) {
    throwError("Link PDF kontrak tidak valid.", 403, "PUBLIC_PDF_TOKEN_INVALID")
  }

  const kontrak = await Kontrak.findOne({
    where: {
      kode_kontrak: kode,
      public_token: token,
    },
  })

  if (!kontrak) {
    throwError("PDF kontrak tidak ditemukan.", 404, "PUBLIC_KONTRAK_PDF_NOT_FOUND")
  }

  return bentukKontrakData(kontrak)
}

function buildPdf(data) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: "A4", margin: 48 })
    const chunks = []

    doc.on("data", (chunk) => chunks.push(chunk))
    doc.on("end", () => resolve(Buffer.concat(chunks)))
    doc.on("error", reject)

    const { kontrak, penyewa, kamar, kos } = data

    header(doc, "Detail Kontrak", kontrak.kode_kontrak)

    section(doc, "Informasi Kontrak", () => {
      infoRow(doc, "Kode kontrak", kontrak.kode_kontrak || `Kontrak #${kontrak.id}`)
      infoRow(doc, "Nama penyewa", penyewa.nama)
      infoRow(doc, "Nomor HP penyewa", penyewa.no_hp || penyewa.nomor_hp || penyewa.telepon || penyewa.no_telpon || "-")
      infoRow(doc, "Nama kos", kos.nama_kos)
      infoRow(doc, "Nomor kamar", kamar.nomor || kamar.nama_kamar || "-")
      infoRow(doc, "Tanggal mulai", formatTanggal(kontrak.tanggal_mulai))
      infoRow(doc, "Tanggal selesai", formatTanggal(kontrak.tanggal_selesai))
      infoRow(doc, "Durasi/siklus sewa", titleCase(kontrak.siklus))
      infoRow(doc, "Harga sewa", formatRupiah(kontrak.harga_sewa))
      infoRow(doc, "Status kontrak", titleCase(kontrak.status))
      infoRow(doc, "Tanggal dibuat", formatTanggal(kontrak.dibuat_pada || kontrak.createdAt))

      if (`${kontrak.catatan || ""}`.trim()) {
        infoRow(doc, "Catatan", kontrak.catatan)
      }
    })

    footer(doc)

    doc.end()
  })
}

exports.generateKontrakPdfBuffer = async (kontrak_id, user_id) => {
  const data = await loadKontrakData(kontrak_id, user_id)
  const buffer = await buildPdf(data)
  const filename = `${safeFileName(`kontrak_${data.kontrak.kode_kontrak || kontrak_id}`)}.pdf`

  return {
    buffer,
    filename,
    data,
  }
}

exports.generateKontrakPdfBufferByPublicToken = async (kode_kontrak, public_token) => {
  const data = await loadKontrakDataByPublicToken(kode_kontrak, public_token)
  const buffer = await buildPdf(data)
  const filename = `${safeFileName(`kontrak_${data.kontrak.kode_kontrak || kode_kontrak}`)}.pdf`

  return {
    buffer,
    filename,
    data,
  }
}

exports.formatRupiah = formatRupiah
exports.formatTanggal = formatTanggal
