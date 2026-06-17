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

function safeFileName(value) {
  return String(value || "kontrak")
    .trim()
    .replace(/[^a-zA-Z0-9._-]+/g, "_")
    .replace(/^_+|_+$/g, "")
}

function line(doc, label, value) {
  doc
    .font("Helvetica-Bold")
    .fontSize(10)
    .fillColor("#374151")
    .text(label, { continued: true, width: 165 })
    .font("Helvetica")
    .fillColor("#111827")
    .text(`  ${value ?? "-"}`)
}

async function loadKontrakData(kontrak_id, user_id) {
  const kontrak = await Kontrak.findOne({
    where: { id: kontrak_id },
    include: [
      {
        model: Penyewa,
        required: true,
      },
      {
        model: Kamar,
        required: true,
        include: {
          model: Kos,
          required: true,
          where: { pemilik_id: user_id },
        },
      },
    ],
  })

  if (!kontrak) {
    throwError(
      "Kontrak tidak ditemukan atau bukan milik user login.",
      404,
      "KONTRAK_NOT_FOUND"
    )
  }

  return {
    kontrak,
    penyewa: kontrak.Penyewa,
    kamar: kontrak.Kamar,
    kos: kontrak.Kamar.Kos,
  }
}

function buildPdf(data) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: "A4", margin: 48 })
    const chunks = []

    doc.on("data", (chunk) => chunks.push(chunk))
    doc.on("end", () => resolve(Buffer.concat(chunks)))
    doc.on("error", reject)

    const { kontrak, penyewa, kamar, kos } = data

    doc
      .font("Helvetica-Bold")
      .fontSize(22)
      .fillColor("#111827")
      .text("Detail Kontrak")
      .moveDown(0.4)
      .font("Helvetica")
      .fontSize(10)
      .fillColor("#6B7280")
      .text("Dokumen ini dibuat otomatis melalui aplikasi Manajemen Kos.")

    doc.moveDown(1.2)
    line(doc, "Kode kontrak", kontrak.kode_kontrak)
    line(doc, "Nama penyewa", penyewa.nama)
    line(doc, "Nomor WhatsApp", penyewa.no_telpon || "-")
    line(doc, "Nama kos", kos.nama_kos)
    line(doc, "Nomor kamar", kamar.nomor)
    line(doc, "Tanggal mulai", formatTanggal(kontrak.tanggal_mulai))
    line(doc, "Tanggal selesai", formatTanggal(kontrak.tanggal_selesai))
    line(doc, "Siklus sewa", kontrak.siklus)
    line(doc, "Harga sewa", formatRupiah(kontrak.harga_sewa))
    line(doc, "Status kontrak", kontrak.status)
    line(doc, "Tanggal dibuat", formatTanggal(kontrak.dibuat_pada))

    if (`${kontrak.catatan || ""}`.trim()) {
      line(doc, "Catatan", kontrak.catatan)
    }

    doc.moveDown(2)
    doc
      .font("Helvetica")
      .fontSize(9)
      .fillColor("#6B7280")
      .text("Dokumen ini dibuat otomatis melalui aplikasi Manajemen Kos.", {
        align: "center",
      })

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

exports.formatRupiah = formatRupiah
exports.formatTanggal = formatTanggal
