const { throwError } = require("../utils/error")

/** Parse YYYY-MM-DD sebagai tanggal lokal (tanpa geser UTC). */
function _parseDateOnly(str) {
  const parts = String(str).trim().split("-")
  if (parts.length !== 3) return new Date(NaN)
  const y = Number(parts[0])
  const m = Number(parts[1])
  const d = Number(parts[2])
  if (!y || !m || !d) return new Date(NaN)
  return new Date(y, m - 1, d)
}
exports.validasi_tagihan = async (body) => {

  const {
    list_item = [],
    kontrak_id,
    periode_awal,
    periode_akhir,
    jatuh_tempo,
    catatan = "empity",
  } = body

  // VALIDASI FIELD WAJIB

  const jenis_enum = ["sewa", "insiden", "denda", "diskon"]

  if (!Array.isArray(list_item)) {
    throwError("list_item harus berupa array", 400, "LIST_ITEM_INVALID")
  }

  for (const i of list_item) {

    if (!i || typeof i !== "object")
      throwError("kesalahan type pada list item", 400, "LIST_ITEM_TYPE_INVALID")

    if (!jenis_enum.includes(i.tipe))
      throwError("ada kesalahan pada type item", 400, "ITEM_TYPE_INVALID")

    if (!i.nama_item)
      throwError("nama item wajib isi", 400, "ITEM_NAME_REQUIRED")

    const nominal = Number(i.nominal)

    if (i.nominal == null || Number.isNaN(nominal) || nominal < 0)
      throwError("nominal item wajib isi", 400, "ITEM_NOMINAL_REQUIRED")

    if (nominal === 0)
      throwError("nominal item harus lebih dari 0", 400, "ITEM_NOMINAL_INVALID")

    i.nominal = nominal
  }

  const kontrakId = Number(kontrak_id)

  if (kontrak_id == null || kontrak_id === "" || Number.isNaN(kontrakId)) {
    throwError("kontrak_id wajib diisi", 400, "KONTRAK_ID_REQUIRED")
  }

  if (!periode_awal) {
    throwError("periode awal wajib diisi", 400, "PERIODE_AWAL_REQUIRED")
  }

  if (!periode_akhir) {
    throwError("periode akhir wajib diisi", 400, "PERIODE_AKHIR_REQUIRED")
  }

  if (!jatuh_tempo) {
    throwError("jatuh tempo wajib diisi", 400, "JATUH_TEMPO_REQUIRED")
  }

  // VALIDASI TANGGAL (lokal, hindari UTC shift dari "YYYY-MM-DD")
  const sekarang = new Date()
  const mulai = _parseDateOnly(periode_awal)
  const selesai = _parseDateOnly(periode_akhir)
  const jatuhTempoDate = _parseDateOnly(jatuh_tempo)

  if (isNaN(mulai.getTime())) {
    throwError("periode_awal tidak valid", 400, "PERIODE_AWAL_INVALID")
  }

  if (isNaN(selesai.getTime())) {
    throwError("periode_akhir tidak valid", 400, "PERIODE_AKHIR_INVALID")
  }

  if (isNaN(jatuhTempoDate.getTime())) {
    throwError("jatuh_tempo tidak valid", 400, "JATUH_TEMPO_INVALID")
  }

  if (sekarang >= selesai) {
    throwError(
      "periode_akhir tidak boleh sebelum hari ini",
      400,
      "PERIODE_AKHIR_EXPIRED"
    )
  }

  if (mulai > selesai) {
    throwError(
      "periode_awal harus sebelum periode_akhir",
      400,
      "PERIODE_RANGE_INVALID"
    )
  }

  if (jatuhTempoDate > selesai || jatuhTempoDate < mulai) {
    throwError(
      "jatuh tempo harus diantara periode awal dan akhir",
      400,
      "JATUH_TEMPO_OUT_OF_RANGE"
    )
  }

  // VALIDASI HARGA
  const total_tagihan = list_item.reduce((total, n) => {
    if (n.tipe === "diskon") return total - n.nominal
    return total + n.nominal
  }, 0)

  if (total_tagihan <= 0) {
    throwError(
      "total tagihan harus lebih dari 0",
      400,
      "TOTAL_TAGIHAN_INVALID"
    )
  }

  //VALIDASI KONSISTENSI
  let lifecycle 

    if (sekarang < mulai) lifecycle = "draft"
    if (sekarang >= mulai) lifecycle = "issued"

  // RETURN DATA BERSIH
  return {
    list_item,
    kontrak_id: kontrakId,
    periode_awal,
    periode_akhir,
    jatuh_tempo,
    total_tagihan,
    catatan,
    lifecycle
  }

}