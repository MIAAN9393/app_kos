const { Op } = require("sequelize")
const Tagihan = require("../model/tagihan")
const TagihanItem = require("../model/tagihan_item")
const Pembayaran = require("../model/pembayaran")
const { throwError } = require("./error")

const hitungTotalTagihanDariItem = (items = []) => {
  return items.reduce((total, item) => {
    const nominal = Number(item.nominal) || 0
    if (item.tipe === "diskon") return total - nominal
    return total + nominal
  }, 0)
}

exports.sync_status_pembayaran = async (tagihan_id, transaction) => {

  const tagihan = await Tagihan.findByPk(tagihan_id, { transaction })

  if (!tagihan) return

  const list_item = await TagihanItem.findAll({
    where: { tagihan_id },
    transaction
  })

  const total_tagihan = hitungTotalTagihanDariItem(list_item)

  const pembayaran_rows = await Pembayaran.findAll({
    where: { tagihan_id },
    transaction
  })

  let total_dibayar = 0

  for (const row of pembayaran_rows) {
    if (row.status === "valid") {
      total_dibayar += Number(row.jumlah_bayar)
    }
    if (row.status === "refund") {
      total_dibayar -= Number(row.jumlah_bayar)
    }
  }

  let status_pembayaran = "belum_bayar"

  if (total_dibayar > 0 && total_dibayar < total_tagihan) {
    status_pembayaran = "sebagian"
  }

  if (total_tagihan > 0 && total_dibayar >= total_tagihan) {
    status_pembayaran = "lunas"
  }

  if (status_pembayaran !== "lunas" && tagihan.jatuh_tempo) {
    const hari_ini = new Date()
    hari_ini.setHours(0, 0, 0, 0)
    const jatuh = new Date(tagihan.jatuh_tempo)
    jatuh.setHours(0, 0, 0, 0)
    if (hari_ini > jatuh) {
      status_pembayaran = "telat"
    }
  }

  await tagihan.update({ status_pembayaran }, { transaction })
}

/**
 * Total pembayaran net (valid − refund) untuk satu tagihan.
 */
exports.hitungTotalDibayar = (pembayaranRows = []) => {
  return pembayaranRows.reduce((total, row) => {
    if (row.status === "valid") {
      return total + Number(row.jumlah_bayar)
    }
    if (row.status === "refund") {
      return total - Number(row.jumlah_bayar)
    }
    return total
  }, 0)
}

exports.hitungTotalTagihanDariItem = hitungTotalTagihanDariItem

/**
 * Sisa tagihan = total_tagihan − total_dibayar (sama seperti di frontend).
 */
exports.hitungSisaTagihan = (totalTagihan, totalDibayar) => {
  return Number(totalTagihan) - Number(totalDibayar)
}

/**
 * Edit / hapus tagihan hanya jika belum ada pembayaran tercatat (sisa pembayaran = 0).
 */
exports.pastikanBolehUbahTagihan = ({ total_tagihan, total_dibayar }) => {
  const dibayar = Number(total_dibayar) || 0
  const sisa = exports.hitungSisaTagihan(total_tagihan, dibayar)

  if (dibayar !== 0) {
    throwError(
      `Tagihan tidak bisa diubah atau dihapus karena sudah ada pembayaran Rp ${dibayar}. Sisa tagihan Rp ${sisa}. Refund semua pembayaran hingga sisa pembayaran nol.`,
      403,
      "TAGIHAN_HAS_PAYMENT"
    )
  }
}

/**
 * Kode unik per tagihan: TGH-202605-0001, TGH-202605-0002, ...
 */
exports.buat_kode_tagihan = async (transaction = null) => {
  const now = new Date()
  const tahun = now.getFullYear()
  const bulan = String(now.getMonth() + 1).padStart(2, "0")
  const prefix = `TGH-${tahun}${bulan}`

  const opts = {
    where: { kode_tagihan: { [Op.like]: `${prefix}%` } },
    order: [["id", "DESC"]],
    attributes: ["kode_tagihan"],
  }
  if (transaction) opts.transaction = transaction

  const terakhir = await Tagihan.findOne(opts)
  let urut = 1

  if (terakhir?.kode_tagihan) {
    const re = new RegExp(`^${prefix}-(\\d{4})$`)
    const match = String(terakhir.kode_tagihan).match(re)
    if (match) {
      urut = parseInt(match[1], 10) + 1
    } else if (terakhir.kode_tagihan === prefix) {
      urut = 2
    } else {
      const count = await Tagihan.count({
        where: { kode_tagihan: { [Op.like]: `${prefix}%` } },
        ...(transaction ? { transaction } : {}),
      })
      urut = count + 1
    }
  }

  return `${prefix}-${String(urut).padStart(4, "0")}`
}

