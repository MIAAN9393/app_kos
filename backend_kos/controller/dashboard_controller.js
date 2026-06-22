const dashboardService = require("../services/dashboard_service")
const SubscriptionService = require("../services/subscription_service")

exports.ambil_ringkasan = async (req, res, next) => {
  try {
    const entitlements = await SubscriptionService.getEntitlements(req.user.id)
    const dashboard = await dashboardService.ambil_ringkasan(req.user.id)
    const data = SubscriptionService.filterDashboardByPlan(dashboard, entitlements)

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
