function pesanDariSequelize(err) {
  const nama = err?.name || ""
  const sqlMsg = err?.parent?.sqlMessage || err?.original?.sqlMessage || ""

  if (nama === "SequelizeUniqueConstraintError") {
    if (sqlMsg.includes("kode_tagihan") || err?.fields?.kode_tagihan) {
      return "Kode tagihan bentrok. Coba simpan lagi."
    }
    if (sqlMsg.includes("kontrak_id") || sqlMsg.includes("periode")) {
      return "Tagihan untuk periode ini sudah ada pada kontrak yang sama."
    }
    return "Data duplikat. Periksa periode atau kode tagihan."
  }

  if (nama === "SequelizeForeignKeyConstraintError") {
    return "Kontrak tidak valid atau tidak ditemukan."
  }

  if (sqlMsg) return sqlMsg

  return null
}

module.exports = (err, req, res, next) => {
  let status = Number(err.status)
  if (!Number.isInteger(status) || status < 400 || status > 599) {
    status = 500
  }

  const code = err.code || "INTERNAL_SERVER_ERROR"
  const dariDb = pesanDariSequelize(err)
  const message = dariDb || err.message || "Terjadi kesalahan pada server"

  if (dariDb && status === 500) {
    status = 400
  }

  console.error(err.stack || err)

  res.status(status).json({
    success: false,
    code,
    message,
    pesan: message,
  })
}
