const dashboardService = require("../services/dashboard_service")

exports.ambil_ringkasan = async (req, res, next) => {
  try {
    const data = await dashboardService.ambil_ringkasan(req.user.id)

    res.status(200).json({
      success: true,
      code: "DASHBOARD_RINGKASAN_SUCCESS",
      pesan: "ringkasan dashboard",
      data,
    })
  } catch (error) {
    next(error)
  }
}
