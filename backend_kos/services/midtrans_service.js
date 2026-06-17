const snap = require("../config/midtrans");
const SubscriptionPayment = require("../model/subscription_payment");
const User = require("../model/user");
const { throwError } = require("../utils/error");

const STATUS_MIDTRANS = [
  "pending",
  "settlement",
  "capture",
  "expire",
  "cancel",
  "deny",
  "failure",
];

function generateOrderId(userId) {
  const random = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `SUB-${userId}-${Date.now()}-${random}`;
}

function isPaidStatus(transactionStatus, fraudStatus) {
  if (transactionStatus === "settlement") {
    return true;
  }

  if (transactionStatus === "capture") {
    return !fraudStatus || fraudStatus === "accept" || fraudStatus === "challenge";
  }

  return false;
}

async function activateSubscription(userId, paket) {
  // TODO: aktifkan paket langganan setelah aturan paket/subscription sudah final.
  return { user_id: userId, paket };
}

exports.createSubscriptionTransaction = async ({ user, paket, jumlah }) => {
  if (!process.env.MIDTRANS_SERVER_KEY) {
    throwError(500, "MIDTRANS_SERVER_KEY belum diatur", "MIDTRANS_CONFIG_MISSING");
  }

  const userId = user.id;
  const orderId = generateOrderId(userId);
  const userDetail = await User.findByPk(userId);

  const pembayaranLangganan = await SubscriptionPayment.create({
    user_id: userId,
    order_id: orderId,
    paket,
    jumlah,
    status: "pending",
  });

  const parameter = {
    transaction_details: {
      order_id: orderId,
      gross_amount: Number(jumlah),
    },
    item_details: [
      {
        id: paket,
        price: Number(jumlah),
        quantity: 1,
        name: `Langganan ${paket}`,
      },
    ],
    customer_details: {
      first_name: userDetail?.nama || `User ${userId}`,
      email: userDetail?.email || user.email || undefined,
      phone: userDetail?.no_telpon || undefined,
    },
  };

  if (process.env.FRONTEND_URL) {
    parameter.callbacks = {
      finish: process.env.FRONTEND_URL,
    };
  }

  try {
    const transaksi = await snap.createTransaction(parameter);

    await pembayaranLangganan.update({
      snap_token: transaksi.token,
      redirect_url: transaksi.redirect_url,
      raw_response: transaksi,
    });

    return {
      token: transaksi.token,
      redirect_url: transaksi.redirect_url,
      order_id: orderId,
    };
  } catch (error) {
    await pembayaranLangganan.update({
      status: "failure",
      raw_response: {
        message: error.message,
        ApiResponse: error.ApiResponse,
      },
    });

    throw error;
  }
};

exports.handleMidtransNotification = async (notificationBody) => {
  const statusResponse = await snap.transaction.notification(notificationBody);
  const orderId = statusResponse.order_id;
  const transactionStatus = statusResponse.transaction_status;
  const fraudStatus = statusResponse.fraud_status;

  const pembayaranLangganan = await SubscriptionPayment.findOne({
    where: {
      order_id: orderId,
    },
  });

  if (!pembayaranLangganan) {
    throwError(404, "pembayaran langganan tidak ditemukan", "SUBSCRIPTION_PAYMENT_NOT_FOUND");
  }

  const status = STATUS_MIDTRANS.includes(transactionStatus)
    ? transactionStatus
    : pembayaranLangganan.status;

  const paidAt =
    !pembayaranLangganan.paid_at && isPaidStatus(transactionStatus, fraudStatus)
      ? new Date()
      : pembayaranLangganan.paid_at;

  await pembayaranLangganan.update({
    status,
    payment_type: statusResponse.payment_type || null,
    fraud_status: fraudStatus || null,
    raw_response: statusResponse,
    paid_at: paidAt,
  });

  if (paidAt) {
    await activateSubscription(pembayaranLangganan.user_id, pembayaranLangganan.paket);
  }

  return pembayaranLangganan;
};

exports.activateSubscription = activateSubscription;
