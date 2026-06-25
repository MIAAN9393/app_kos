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
    const body = req.body || {};
    console.log("=== MIDTRANS WEBHOOK MASUK ===", {
      order_id: body.order_id,
      transaction_status: body.transaction_status,
      fraud_status: body.fraud_status,
      payment_type: body.payment_type,
    });

    const data = await MidtransService.handleMidtransNotification(body);

    res.status(200).json({
      success: true,
      code: data?.ignored ? "MIDTRANS_NOTIFICATION_IGNORED" : "MIDTRANS_NOTIFICATION_OK",
      pesan: data?.ignored ? "notification diabaikan" : "notification diterima",
    });
  } catch (error) {
    next(error);
  }
};
