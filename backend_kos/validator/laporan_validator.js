const { throwError } = require("../utils/error")
const { parseBulan } = require("../utils/laporan_helper")

/**
 * Validasi query laporan (keuangan & tagihan).
 * Query: bulan_mulai, bulan_akhir (YYYY-MM), kos_ids opsional (contoh: "1,2,3").
 */
exports.validasi_query_laporan = (query = {}) => {
  const { bulan_mulai, bulan_akhir, kos_id, kos_ids } = query

  if (!bulan_mulai || !bulan_akhir) {
    throwError(
      "bulan_mulai dan bulan_akhir wajib diisi (format YYYY-MM)",
      400,
      "BULAN_REQUIRED"
    )
  }

  if (!parseBulan(bulan_mulai) || !parseBulan(bulan_akhir)) {
    throwError("format bulan harus YYYY-MM", 400, "BULAN_FORMAT_INVALID")
  }

  let kosIds = null

  if (kos_ids !== undefined && kos_ids !== null && kos_ids !== "") {
    kosIds = String(kos_ids)
      .split(",")
      .map((s) => Number(s.trim()))
      .filter((id) => id > 0 && !Number.isNaN(id))

    if (kosIds.length === 0) {
      throwError("kos_ids tidak valid", 400, "KOS_IDS_INVALID")
    }
  } else if (kos_id !== undefined && kos_id !== null && kos_id !== "") {
    const satu = Number(kos_id)
    if (!satu || Number.isNaN(satu)) {
      throwError("kos_id tidak valid", 400, "KOS_ID_INVALID")
    }
    kosIds = [satu]
  }

  return {
    bulan_mulai: String(bulan_mulai).trim(),
    bulan_akhir: String(bulan_akhir).trim(),
    kos_ids: kosIds,
  }
}
