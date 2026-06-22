const laporanService = require("../services/laporan_service")
const SubscriptionService = require("../services/subscription_service")

/**
 * GET laporan keuangan — uang masuk per bulan (tanggal_bayar).
 */
exports.ambil_laporan_keuangan = async (req, res, next) => {
  try {
    await SubscriptionService.assertLaporanRange(req.user.id, req.query)

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
  } catch (error) {
    next(error)
  }
}
