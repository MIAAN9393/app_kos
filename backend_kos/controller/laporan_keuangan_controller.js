const laporanService = require("../services/laporan_service")

/**
 * GET laporan keuangan — uang masuk per bulan (tanggal_bayar).
 */
exports.ambil_laporan_keuangan = async (req, res, next) => {
  try {
    const data = await laporanService.ambil_laporan_keuangan(
      req.user.id,
      req.query
    )

    res.status(200).json({
      success: true,
      code: "LAPORAN_KEUANGAN_SUCCESS",
      pesan: "laporan keuangan",
      data,
    })
    
    console.log("LAPORAN KEUANGAN",data)
  } catch (error) {
    next(error)
  }
}
