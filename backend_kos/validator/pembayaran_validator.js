const { throwError } = require("../utils/error")

exports.validasi_pembayaran = (body) => {
  const {
    tagihan_id,
    jumlah_bayar,
  } = body

  if (!tagihan_id) {
    throwError(400, "tagihan_id wajib diisi")
  }

  if (jumlah_bayar === undefined || jumlah_bayar === null) {
    throwError(400, "jumlah_bayar wajib diisi")
  }

  if (
    typeof jumlah_bayar !== "number" ||
    Number.isNaN(jumlah_bayar)
  ) {
    throwError(400, "jumlah_bayar harus angka")
  }

  if (jumlah_bayar <= 0) {
    throwError(400, "jumlah_bayar harus lebih dari 0")
  }

  return {
    tagihan_id,
    jumlah_bayar
  }
}

exports.validasi_refund = (body) => {

  const {
    pembayaran_id,
    jumlah_refund
  } = body

  // pembayaran_id

  if (
    !Number.isInteger(pembayaran_id) ||
    pembayaran_id <= 0
  ) {
    throwError(
      400,
      "pembayaran_id tidak valid"
    )
  }

  // jumlah_refund wajib

  if (
    jumlah_refund === undefined ||
    jumlah_refund === null
  ) {
    throwError(
      400,
      "jumlah_refund wajib diisi"
    )
  }

  // jumlah_refund harus angka

  if (
    typeof jumlah_refund !== "number" ||
    Number.isNaN(jumlah_refund)
  ) {
    throwError(
      400,
      "jumlah_refund harus angka"
    )
  }

  // jumlah_refund > 0

  if (jumlah_refund <= 0) {
    throwError(
      400,
      "jumlah_refund harus lebih dari 0"
    )
  }

  // jumlah_refund integer

  if (!Number.isInteger(jumlah_refund)) {
    throwError(
      400,
      "jumlah_refund harus bilangan bulat"
    )
  }

  return {
    pembayaran_id,
    jumlah_refund
  }
}