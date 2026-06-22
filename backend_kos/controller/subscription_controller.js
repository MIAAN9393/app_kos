const SubscriptionService = require("../services/subscription_service");

exports.ambil_subscription_saya = async (req, res, next) => {
  try {
    const entitlements = await SubscriptionService.getEntitlements(req.user.id);
    const usage = await SubscriptionService.getUsage(req.user.id);

    res.status(200).json({
      success: true,
      code: "SUBSCRIPTION_ME_SUCCESS",
      pesan: "subscription aktif",
      data: {
        paket: entitlements.paket,
        limits: entitlements.limits,
        usage,
        features: entitlements.features,
        subscription: entitlements.subscription,
      },
    });
  } catch (error) {
    next(error);
  }
};
