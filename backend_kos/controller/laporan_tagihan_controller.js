const laporanService = require("../services/laporan_service")

/**
 * GET laporan tagihan — tagihan per bulan jatuh_tempo.
 */
exports.ambil_laporan_tagihan = async (req, res, next) => {
  try {
    const data = await laporanService.ambil_laporan_tagihan(
      req.user.id,
      req.query
    )

    res.status(200).json({
      success: true,
      code: "LAPORAN_TAGIHAN_SUCCESS",
      pesan: "laporan tagihan",
      data,
    })
  } catch (error) {
    next(error)
  }
}
