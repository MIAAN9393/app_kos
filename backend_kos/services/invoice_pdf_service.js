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

function line(doc, label, value) {
  doc
    .font("Helvetica-Bold")
    .fontSize(10)
    .fillColor("#374151")
    .text(label, { continued: true, width: 170 })
    .font("Helvetica")
    .fillColor("#111827")
    .text(`  ${value ?? "-"}`)
}

function tableRow(doc, cells, widths, options = {}) {
  const y = doc.y
  const x = doc.x
  const height = options.height || 22

  if (options.fill) {
    doc.rect(x, y, widths.reduce((a, b) => a + b, 0), height).fill(options.fill)
  }

  doc.fillColor(options.color || "#111827").font(options.bold ? "Helvetica-Bold" : "Helvetica")
  let currentX = x
  for (let i = 0; i < cells.length; i += 1) {
    doc.text(String(cells[i] ?? "-"), currentX + 6, y + 6, {
      width: widths[i] - 12,
      align: i === cells.length - 1 ? "right" : "left",
    })
    currentX += widths[i]
  }

  doc.y = y + height
}

async function loadInvoiceData(tagihan_id, user_id) {
  const tagihan = await Tagihan.findOne({
    where: { id: tagihan_id },
    include: {
      model: Kontrak,
      required: true,
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
    },
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

  const totalDibayar = hitungTotalDibayar(pembayaran)
  const sisaBayar = hitungSisaTagihan(tagihan.total_tagihan, totalDibayar)

  return {
    tagihan,
    kontrak: tagihan.Kontrak,
    penyewa: tagihan.Kontrak.Penyewa,
    kamar: tagihan.Kontrak.Kamar,
    kos: tagihan.Kontrak.Kamar.Kos,
    items,
    totalDibayar,
    sisaBayar,
  }
}

function buildPdf(data) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: "A4", margin: 48 })
    const chunks = []

    doc.on("data", (chunk) => chunks.push(chunk))
    doc.on("end", () => resolve(Buffer.concat(chunks)))
    doc.on("error", reject)

    const { tagihan, penyewa, kamar, kos, items, totalDibayar, sisaBayar } = data
    const periode = `${formatTanggal(tagihan.periode_awal)} - ${formatTanggal(tagihan.periode_akhir)}`

    doc
      .font("Helvetica-Bold")
      .fontSize(22)
      .fillColor("#111827")
      .text("Invoice Tagihan")
      .moveDown(0.4)
      .font("Helvetica")
      .fontSize(10)
      .fillColor("#6B7280")
      .text("Dokumen ini dibuat otomatis melalui aplikasi Manajemen Kos.")

    doc.moveDown(1.2)
    line(doc, "Kode tagihan", tagihan.kode_tagihan)
    line(doc, "Nama penyewa", penyewa.nama)
    line(doc, "Nomor WhatsApp", penyewa.no_telpon || "-")
    line(doc, "Nama kos", kos.nama_kos)
    line(doc, "Nomor kamar", kamar.nomor)
    line(doc, "Periode tagihan", periode)
    line(doc, "Jatuh tempo", formatTanggal(tagihan.jatuh_tempo))
    line(doc, "Status pembayaran", statusLabel(tagihan.status_pembayaran))
    line(doc, "Tanggal cetak", formatTanggal(new Date()))

    doc.moveDown(1)
    doc.font("Helvetica-Bold").fontSize(13).fillColor("#111827").text("Daftar Item Tagihan")
    doc.moveDown(0.4)
    tableRow(doc, ["Item", "Tipe", "Nominal"], [260, 90, 140], {
      fill: "#F3F4F6",
      bold: true,
      height: 26,
    })

    if (!items.length) {
      tableRow(doc, ["Tidak ada item", "-", "-"], [260, 90, 140])
    } else {
      for (const item of items) {
        tableRow(
          doc,
          [item.nama_item, item.tipe, formatRupiah(item.nominal)],
          [260, 90, 140],
          { height: 24 }
        )
      }
    }

    doc.moveDown(1)
    line(doc, "Total tagihan", formatRupiah(tagihan.total_tagihan))
    line(doc, "Total dibayar", formatRupiah(totalDibayar))
    line(doc, "Sisa bayar", formatRupiah(sisaBayar))

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

exports.formatRupiah = formatRupiah
exports.formatTanggal = formatTanggal
