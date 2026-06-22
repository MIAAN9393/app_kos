require("../model/index")

const PDFDocument = require("pdfkit")
const Tagihan = require("../model/tagihan")
const TagihanItem = require("../model/tagihan_item")
const Pembayaran = require("../model/pembayaran")
const Kontrak = require("../model/kontrak")
const Kamar = require("../model/kamar")
const Kos = require("../model/kos")
const Penyewa = require("../model/penyewa")
const { throwError } = require("../utils/error")
const { hitungTotalDibayar, hitungSisaTagihan } = require("../utils/tagihan_helper")

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

function statusLabel(value) {
  const map = {
    belum_bayar: "Belum bayar",
    sebagian: "Sebagian",
    lunas: "Lunas",
    telat: "Telat",
  }
  return map[value] || value || "-"
}

function safeFileName(value) {
  return String(value || "invoice")
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

function tableRow(doc, cells, widths, options = {}) {
  const y = doc.y
  const x = options.x || 44
  const paddingX = 6
  const paddingY = 5
  const font = options.bold ? "Helvetica-Bold" : "Helvetica"
  const fontSize = options.fontSize || 9
  doc.font(font).fontSize(fontSize)

  const contentHeight = cells.reduce((max, cell, index) => {
    const cellHeight = doc.heightOfString(String(cell ?? "-"), {
      width: widths[index] - paddingX * 2,
    })
    return Math.max(max, cellHeight)
  }, 0)
  const height = Math.max(options.height || 24, contentHeight + paddingY * 2)

  let currentX = x
  for (let i = 0; i < cells.length; i += 1) {
    if (options.fill) {
      doc.rect(currentX, y, widths[i], height).fill(options.fill)
    }
    doc
      .rect(currentX, y, widths[i], height)
      .strokeColor("#E5E7EB")
      .stroke()
      .fillColor(options.color || "#111827")
      .font(font)
      .fontSize(fontSize)

    doc.text(String(cells[i] ?? "-"), currentX + paddingX, y + paddingY, {
      width: widths[i] - paddingX * 2,
      align: i === cells.length - 1 ? "right" : "left",
    })
    currentX += widths[i]
  }

  doc.y = y + height
}

function table(doc, headers, rows, widths, options = {}) {
  const x = options.x || 44
  if (!rows.length) {
    doc.font("Helvetica").fontSize(10).fillColor("#6B7280").text("Tidak ada data.")
    return
  }

  tableRow(doc, headers, widths, {
    x,
    fill: "#2563EB",
    color: "#FFFFFF",
    bold: true,
    height: 26,
  })

  for (const row of rows) {
    tableRow(doc, row, widths, { x, height: 24 })
  }
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

async function ambilDataRelasiInvoice(tagihan, user_id = null) {
  const kontrak =
    ambilRelasi(tagihan, "Kontrak") ||
    (await Kontrak.findByPk(tagihan.kontrak_id))
  const penyewa =
    ambilRelasi(kontrak, "Penyewa") ||
    (kontrak ? await Penyewa.findByPk(kontrak.penyewa_id) : null)
  const kamar =
    ambilRelasi(kontrak, "Kamar") ||
    (kontrak ? await Kamar.findByPk(kontrak.kamar_id) : null)
  const kos =
    ambilRelasi(kamar, "Kos") ||
    (kamar ? await Kos.findByPk(kamar.kos_id) : null)

  if (!kontrak || !penyewa || !kamar || !kos) {
    throwError(
      "Data relasi tagihan tidak lengkap untuk membuat PDF.",
      404,
      "TAGIHAN_PDF_RELATION_NOT_FOUND"
    )
  }

  if (user_id && Number(kos.pemilik_id) !== Number(user_id)) {
    throwError(
      "Tagihan tidak ditemukan atau bukan milik user login.",
      404,
      "TAGIHAN_NOT_FOUND"
    )
  }

  return { kontrak, penyewa, kamar, kos }
}

async function bentukInvoiceData({ tagihan, items, pembayaran, user_id = null }) {
  const { kontrak, penyewa, kamar, kos } = await ambilDataRelasiInvoice(
    tagihan,
    user_id
  )
  const totalDibayar = hitungTotalDibayar(pembayaran)
  const sisaBayar = hitungSisaTagihan(tagihan.total_tagihan, totalDibayar)

  return {
    tagihan,
    kontrak,
    penyewa,
    kamar,
    kos,
    items,
    pembayaran,
    totalDibayar,
    sisaBayar,
  }
}

async function loadInvoiceData(tagihan_id, user_id) {
  const tagihan = await Tagihan.findOne({
    where: { id: tagihan_id },
  })

  if (!tagihan) {
    throwError("Tagihan tidak ditemukan atau bukan milik user login.", 404, "TAGIHAN_NOT_FOUND")
  }

  const items = await TagihanItem.findAll({
    where: { tagihan_id: tagihan.id },
    order: [["id", "ASC"]],
  })

  const pembayaran = await Pembayaran.findAll({
    where: { tagihan_id: tagihan.id },
    order: [["id", "ASC"]],
  })

  return bentukInvoiceData({ tagihan, items, pembayaran, user_id })
}

async function loadInvoiceDataByPublicToken(kode_tagihan, public_token) {
  const kode = String(kode_tagihan || "").trim()
  const token = String(public_token || "").trim()
  if (!kode || !token) {
    throwError("Link PDF tagihan tidak valid.", 403, "PUBLIC_PDF_TOKEN_INVALID")
  }

  const tagihan = await Tagihan.findOne({
    where: {
      kode_tagihan: kode,
      public_token: token,
    },
  })

  if (!tagihan) {
    throwError("PDF tagihan tidak ditemukan.", 404, "PUBLIC_TAGIHAN_PDF_NOT_FOUND")
  }

  const items = await TagihanItem.findAll({
    where: { tagihan_id: tagihan.id },
    order: [["id", "ASC"]],
  })

  const pembayaran = await Pembayaran.findAll({
    where: { tagihan_id: tagihan.id },
    order: [["id", "ASC"]],
  })

  return bentukInvoiceData({ tagihan, items, pembayaran })
}

function buildPdf(data) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: "A4", margin: 48 })
    const chunks = []

    doc.on("data", (chunk) => chunks.push(chunk))
    doc.on("end", () => resolve(Buffer.concat(chunks)))
    doc.on("error", reject)

    const { tagihan, penyewa, kamar, kos, items, pembayaran, totalDibayar, sisaBayar } = data
    const periode = `${formatTanggal(tagihan.periode_awal)} - ${formatTanggal(tagihan.periode_akhir)}`
    const lokasi = `${kos.nama_kos || "-"} / Kamar ${kamar.nomor || "-"}`

    header(doc, "Invoice Tagihan", tagihan.kode_tagihan)

    section(doc, "Informasi Tagihan", () => {
      infoRow(doc, "Kode tagihan", tagihan.kode_tagihan)
      infoRow(doc, "Nama penyewa", penyewa.nama)
      infoRow(doc, "Kos dan kamar", lokasi)
      infoRow(doc, "Periode tagihan", periode)
      infoRow(doc, "Jatuh tempo", formatTanggal(tagihan.jatuh_tempo))
      infoRow(doc, "Status pembayaran", statusLabel(tagihan.status_pembayaran))
    })

    section(doc, "Daftar Item Tagihan", (x, width) => {
      table(
        doc,
        ["Item", "Nominal"],
        items.map((item) => [
          item.nama_item || item.nama || item.label || titleCase(item.tipe),
          formatRupiah(item.nominal || item.jumlah),
        ]),
        [Math.floor(width * 0.64), width - Math.floor(width * 0.64)],
        { x }
      )
    })

    section(doc, "Ringkasan Pembayaran", () => {
      infoRow(doc, "Total tagihan", formatRupiah(tagihan.total_tagihan))
      infoRow(doc, "Total dibayar", formatRupiah(totalDibayar))
      infoRow(doc, "Sisa bayar", formatRupiah(sisaBayar))
      infoRow(doc, "Tanggal cetak", formatTanggal(new Date()))
    })

    section(doc, "Riwayat Pembayaran", (x, width) => {
      const tanggalWidth = Math.floor(width * 0.38)
      const nominalWidth = Math.floor(width * 0.34)
      table(
        doc,
        ["Tanggal", "Nominal", "Status"],
        pembayaran.map((item) => [
          formatTanggal(item.dibuat_pada),
          formatRupiah(item.jumlah_bayar),
          titleCase(item.status),
        ]),
        [tanggalWidth, nominalWidth, width - tanggalWidth - nominalWidth],
        { x }
      )
    })

    footer(doc)

    doc.end()
  })
}

exports.generateInvoicePdfBuffer = async (tagihan_id, user_id) => {
  const data = await loadInvoiceData(tagihan_id, user_id)
  const buffer = await buildPdf(data)
  const filename = `${safeFileName(`invoice_${data.tagihan.kode_tagihan || tagihan_id}`)}.pdf`

  return {
    buffer,
    filename,
    data,
  }
}

exports.generateInvoicePdfBufferByPublicToken = async (kode_tagihan, public_token) => {
  const data = await loadInvoiceDataByPublicToken(kode_tagihan, public_token)
  const buffer = await buildPdf(data)
  const filename = `${safeFileName(`invoice_${data.tagihan.kode_tagihan || kode_tagihan}`)}.pdf`

  return {
    buffer,
    filename,
    data,
  }
}

exports.formatRupiah = formatRupiah
exports.formatTanggal = formatTanggal
