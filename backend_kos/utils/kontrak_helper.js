const { Op } = require("sequelize")
const Kontrak = require("../model/kontrak")


exports.buat_kode_kontrak = async (transaction = null) => {
  const now = new Date()
  const tahun = now.getFullYear()
  const bulan = String(now.getMonth() + 1).padStart(2, "0")
  const prefix = `KTR-${tahun}${bulan}`

  const opts = {
    where: { kode_kontrak: { [Op.like]: `${prefix}%` } },
    order: [["id", "DESC"]],
    attributes: ["kode_kontrak"],
  }
  if (transaction) opts.transaction = transaction

  const terakhir = await Kontrak.findOne(opts)
  let urut = 1

  if (terakhir?.kode_kontrak) {
    const re = new RegExp(`^${prefix}-(\\d{4})$`)
    const match = String(terakhir.kode_kontrak).match(re)
    if (match) {
      urut = parseInt(match[1], 10) + 1
    } else if (terakhir.kode_kontrak === prefix) {
      urut = 2
    } else {
      const count = await Kontrak.count({
        where: { kode_kontrak: { [Op.like]: `${prefix}%` } },
        ...(transaction ? { transaction } : {}),
      })
      urut = count + 1
    }
  }

  return `${prefix}-${String(urut).padStart(4, "0")}`
}