const MidtransService = require("../services/midtrans_service");
const { throwError } = require("../utils/error");

exports.create_subscription = async (req, res, next) => {
  try {
    const { paket, jumlah } = req.body;
    const jumlahAngka = Number(jumlah);

    if (!paket) {
      throwError(400, "paket wajib diisi", "PAKET_REQUIRED");
    }

    if (jumlah === undefined || jumlah === null || !Number.isFinite(jumlahAngka) || jumlahAngka <= 0) {
      throwError(400, "jumlah wajib angka lebih dari 0", "JUMLAH_INVALID");
    }

    const data = await MidtransService.createSubscriptionTransaction({
      user: req.user,
      paket,
      jumlah: jumlahAngka,
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
