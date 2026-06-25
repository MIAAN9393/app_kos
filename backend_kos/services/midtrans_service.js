const snap = require("../config/midtrans");
const SubscriptionPayment = require("../model/subscription_payment");
const User = require("../model/user");
const SubscriptionService = require("./subscription_service");
const { PLANS } = require("../config/subscription_plans");
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
  return SubscriptionService.activateSubscription({
    userId,
    paket,
  });
}

function getPaidPlanOrThrow(paket) {
  const kodePaket = String(paket || "").toLowerCase();
  const plan = PLANS[kodePaket];

  if (!plan || !["starter", "pro"].includes(kodePaket)) {
    throwError(400, "paket tidak valid", "PAKET_INVALID");
  }

  if (!Number.isFinite(Number(plan.harga)) || Number(plan.harga) <= 0) {
    throwError(500, "harga paket belum dikonfigurasi", "SUBSCRIPTION_PRICE_MISSING");
  }

  return plan;
}

exports.createSubscriptionTransaction = async ({ user, paket }) => {
  if (!process.env.MIDTRANS_SERVER_KEY) {
    throwError(500, "MIDTRANS_SERVER_KEY belum diatur", "MIDTRANS_CONFIG_MISSING");
  }

  const plan = getPaidPlanOrThrow(paket);
  const jumlah = Number(plan.harga);
  const userId = user.id;
  const orderId = generateOrderId(userId);
  const userDetail = await User.findByPk(userId);

  await SubscriptionService.assertCanPurchasePlan(userId, plan.paket);

  const pembayaranLangganan = await SubscriptionPayment.create({
    user_id: userId,
    order_id: orderId,
    paket: plan.paket,
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
        id: plan.paket,
        price: Number(jumlah),
        quantity: 1,
        name: `Langganan ${plan.paket}`,
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
  const notificationOrderId = notificationBody?.order_id;

  if (!notificationOrderId) {
    console.warn("Midtrans notification ignored: order_id kosong");
    return {
      ignored: true,
      reason: "ORDER_ID_EMPTY",
    };
  }

  const pembayaranLangganan = await SubscriptionPayment.findOne({
    where: {
      order_id: notificationOrderId,
    },
  });

  if (!pembayaranLangganan) {
    console.warn("Midtrans notification ignored: order_id tidak ditemukan", {
      order_id: notificationOrderId,
      transaction_status: notificationBody?.transaction_status,
    });
    return {
      ignored: true,
      reason: "ORDER_ID_NOT_FOUND",
      order_id: notificationOrderId,
    };
  }

  const statusResponse = await snap.transaction.notification(notificationBody);
  const transactionStatus = statusResponse.transaction_status;
  const fraudStatus = statusResponse.fraud_status;

  const status = STATUS_MIDTRANS.includes(transactionStatus)
    ? transactionStatus
    : pembayaranLangganan.status;

  const baruDibayar =
    !pembayaranLangganan.paid_at && isPaidStatus(transactionStatus, fraudStatus);
  const paidAt = baruDibayar ? new Date() : pembayaranLangganan.paid_at;

  await pembayaranLangganan.update({
    status,
    payment_type: statusResponse.payment_type || null,
    fraud_status: fraudStatus || null,
    raw_response: statusResponse,
    paid_at: paidAt,
  });

  if (baruDibayar) {
    await SubscriptionService.activateSubscription({
      userId: pembayaranLangganan.user_id,
      paket: pembayaranLangganan.paket,
      sourcePaymentId: pembayaranLangganan.id,
    });
  }

  return pembayaranLangganan;
};

exports.activateSubscription = activateSubscription;
