const MidtransService = require("../services/midtrans_service");
const { throwError } = require("../utils/error");

exports.create_subscription = async (req, res, next) => {
  try {
    const { paket } = req.body;

    if (!paket) {
      throwError(400, "paket wajib diisi", "PAKET_REQUIRED");
    }

    if (!["starter", "pro"].includes(String(paket).toLowerCase())) {
      throwError(400, "paket tidak valid", "PAKET_INVALID");
    }

    const data = await MidtransService.createSubscriptionTransaction({
      user: req.user,
      paket: String(paket).toLowerCase(),
    });

    res.status(200).json({
      order_id: data.order_id,
      snap_token: data.token,
      redirect_url: data.redirect_url,
    });
  } catch (error) {
    next(error);
  }
};

exports.notification = async (req, res, next) => {
  try {
    await MidtransService.handleMidtransNotification(req.body);

    res.status(200).json({
      success: true,
      code: "MIDTRANS_NOTIFICATION_OK",
      pesan: "notification diterima",
    });
  } catch (error) {
    next(error);
  }
};
