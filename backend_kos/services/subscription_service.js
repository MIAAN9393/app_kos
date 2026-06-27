require("../model/index");

const { Op } = require("sequelize");
const sequelize = require("../config/database");
const Kos = require("../model/kos");
const Kamar = require("../model/kamar");
const Penyewa = require("../model/penyewa");
const UserSubscription = require("../model/user_subscription");
const { getPlan } = require("../config/subscription_plans");
const { throwError } = require("../utils/error");
const FcmService = require("./fcm_service");

const DEFAULT_DURATION_DAYS = 30;
const GRACE_PERIOD_DAYS = 10;
const REMINDER_BEFORE_EXPIRED = new Set([7, 3, 1]);
const REMINDER_AFTER_EXPIRED = new Set([5, 9, 10]);

function tambahHari(date, days) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

function awalHari(date) {
  const result = new Date(date);
  result.setHours(0, 0, 0, 0);
  return result;
}

function selisihHari(target, base = new Date()) {
  const targetDay = awalHari(target);
  const baseDay = awalHari(base);
  return Math.round((targetDay - baseDay) / (24 * 60 * 60 * 1000));
}

function currentMonthKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
}

function pastikanBelumMelebihiLimit({ nama, current, limit }) {
  if (limit === null || limit === undefined) return;
  if (current >= limit) {
    throwError(
      `Limit ${nama} paket anda sudah tercapai (${current}/${limit})`,
      403,
      "SUBSCRIPTION_LIMIT_REACHED"
    );
  }
}

function buatWarning(status, subscription) {
  if (status === "past_due") {
    const daysLeft = subscription?.grace_until
      ? Math.max(0, selisihHari(subscription.grace_until))
      : 0;
    return {
      type: "SUBSCRIPTION_PAST_DUE",
      pesan: `Langganan sudah habis. Masa tenggang tersisa ${daysLeft} hari.`,
      days_left: daysLeft,
    };
  }

  if (status === "expired") {
    return {
      type: "SUBSCRIPTION_EXPIRED",
      pesan: "Langganan sudah berakhir. Fitur premium terkunci sampai bayar ulang.",
      days_left: 0,
    };
  }

  return null;
}

exports.refreshSubscriptionStatuses = async (userId = null) => {
  const now = new Date();

  const activeWhere = {
    status: "active",
    expired_at: { [Op.ne]: null, [Op.lte]: now },
  };
  if (userId) activeWhere.user_id = userId;

  const activeExpired = await UserSubscription.findAll({
    where: activeWhere,
  });

  let movedToPastDue = 0;
  let movedToExpired = 0;

  for (const subscription of activeExpired) {
    const graceUntil = tambahHari(subscription.expired_at, GRACE_PERIOD_DAYS);
    if (graceUntil <= now) {
      await subscription.update({
        status: "expired",
        grace_until: graceUntil,
      });
      movedToExpired += 1;
    } else {
      await subscription.update({
        status: "past_due",
        grace_until: graceUntil,
      });
      movedToPastDue += 1;
    }
  }

  const pastDueWhere = {
    status: "past_due",
    grace_until: { [Op.ne]: null, [Op.lte]: now },
  };
  if (userId) pastDueWhere.user_id = userId;

  const [expiredPastDue] = await UserSubscription.update(
    { status: "expired" },
    { where: pastDueWhere }
  );
  movedToExpired += expiredPastDue;

  return {
    moved_to_past_due: movedToPastDue,
    moved_to_expired: movedToExpired,
  };
};

exports.getSubscriptionState = async (userId) => {
  await exports.refreshSubscriptionStatuses(userId);

  const now = new Date();
  const subscription = await UserSubscription.findOne({
    where: {
      user_id: userId,
      status: { [Op.in]: ["active", "past_due"] },
      [Op.or]: [
        { status: "active", expired_at: null },
        { status: "active", expired_at: { [Op.gt]: now } },
        { status: "past_due", grace_until: { [Op.gt]: now } },
      ],
    },
    order: [
      ["status", "ASC"],
      ["expired_at", "DESC"],
      ["id", "DESC"],
    ],
  });

  if (!subscription) {
    const latestExpired = await UserSubscription.findOne({
      where: { user_id: userId },
      order: [["id", "DESC"]],
    });

    return {
      status: latestExpired ? "expired" : "free",
      paket: "free",
      subscription: latestExpired || null,
      warning: latestExpired ? buatWarning("expired", latestExpired) : null,
      is_grace: false,
    };
  }

  return {
    status: subscription.status,
    paket: subscription.paket,
    subscription,
    warning: buatWarning(subscription.status, subscription),
    is_grace: subscription.status === "past_due",
  };
};

exports.getActiveSubscription = async (userId) => {
  const state = await exports.getSubscriptionState(userId);
  return state.status === "active" ? state.subscription : null;
};

exports.getEntitlements = async (userId) => {
  const state = await exports.getSubscriptionState(userId);
  const plan = getPlan(
    ["active", "past_due"].includes(state.status) ? state.paket : "free"
  );

  return {
    paket: plan.paket,
    status: state.status,
    subscription: state.subscription,
    warning: state.warning,
    is_grace: state.is_grace,
    limits: plan.limits,
    features: plan.features,
  };
};

exports.getActiveOrGraceSubscription = async (userId) => {
  const state = await exports.getSubscriptionState(userId);
  return ["active", "past_due"].includes(state.status)
    ? state.subscription
    : null;
};

exports.getUsage = async (userId) => {
  const kos = await Kos.count({
    where: {
      pemilik_id: userId,
      status: "aktif",
    },
  });

  const kamar = await Kamar.count({
    include: {
      model: Kos,
      required: true,
      where: {
        pemilik_id: userId,
        status: "aktif",
      },
    },
    where: {
      status: "aktif",
    },
  });

  const penyewaAktif = await Penyewa.count({
    where: {
      pemilik_id: userId,
      status: "aktif",
    },
  });

  return {
    kos,
    kamar,
    penyewa_aktif: penyewaAktif,
  };
};

exports.activateSubscription = async ({
  userId,
  paket,
  sourcePaymentId = null,
  durationDays = DEFAULT_DURATION_DAYS,
}) => {
  if (sourcePaymentId) {
    const existing = await UserSubscription.findOne({
      where: { source_payment_id: sourcePaymentId },
    });
    if (existing) return existing;
  }

  await exports.refreshSubscriptionStatuses(userId);

  const plan = getPlan(paket);

  return sequelize.transaction(async (t) => {
    if (sourcePaymentId) {
      const existing = await UserSubscription.findOne({
        where: { source_payment_id: sourcePaymentId },
        transaction: t,
        lock: t.LOCK.UPDATE,
      });
      if (existing) return existing;
    }

    const now = new Date();
    const activeLama = await UserSubscription.findOne({
      where: {
        user_id: userId,
        status: "active",
        expired_at: { [Op.gt]: now },
      },
      order: [["expired_at", "DESC"], ["id", "DESC"]],
      transaction: t,
      lock: t.LOCK.UPDATE,
    });

    const perpanjangPaketSama =
      activeLama &&
      activeLama.paket === plan.paket &&
      activeLama.expired_at;
    const baseExpiredAt = perpanjangPaketSama ? activeLama.expired_at : now;
    const expiredAt =
      plan.paket === "free" ? null : tambahHari(baseExpiredAt, durationDays);
    const graceUntil =
      plan.paket === "free" || !expiredAt
        ? null
        : tambahHari(expiredAt, GRACE_PERIOD_DAYS);

    await UserSubscription.update(
      { status: "expired" },
      {
        where: {
          user_id: userId,
          status: { [Op.in]: ["active", "past_due"] },
        },
        transaction: t,
      }
    );

    return UserSubscription.create(
      {
        user_id: userId,
        paket: plan.paket,
        status: "active",
        source_payment_id: sourcePaymentId,
        started_at: now,
        expired_at: expiredAt,
        grace_until: graceUntil,
      },
      { transaction: t }
    );
  });
};

exports.assertCanCreateKos = async (userId) => {
  const entitlements = await exports.getEntitlements(userId);
  const total = await Kos.count({
    where: {
      pemilik_id: userId,
      status: "aktif",
    },
  });

  pastikanBelumMelebihiLimit({
    nama: "kos",
    current: total,
    limit: entitlements.limits.kos,
  });
};

exports.ensureCanCreateKos = exports.assertCanCreateKos;

exports.assertCanCreateKamar = async (userId) => {
  const entitlements = await exports.getEntitlements(userId);
  const total = await Kamar.count({
    include: {
      model: Kos,
      required: true,
      where: {
        pemilik_id: userId,
        status: "aktif",
      },
    },
    where: {
      status: "aktif",
    },
  });

  pastikanBelumMelebihiLimit({
    nama: "kamar",
    current: total,
    limit: entitlements.limits.kamar,
  });
};

exports.ensureCanCreateKamar = exports.assertCanCreateKamar;

exports.assertCanCreatePenyewa = async (userId) => {
  const entitlements = await exports.getEntitlements(userId);
  const total = await Penyewa.count({
    where: {
      pemilik_id: userId,
      status: "aktif",
    },
  });

  pastikanBelumMelebihiLimit({
    nama: "penyewa aktif",
    current: total,
    limit: entitlements.limits.penyewa_aktif,
  });
};

exports.ensureCanCreatePenyewa = exports.assertCanCreatePenyewa;

exports.assertFeature = async (userId, featureName) => {
  const entitlements = await exports.getEntitlements(userId);
  if (!entitlements.features[featureName]) {
    throwError(
      `Fitur ini membutuhkan paket yang lebih tinggi`,
      403,
      "SUBSCRIPTION_FEATURE_LOCKED"
    );
  }
  return entitlements;
};

exports.ensureCanUseFeature = exports.assertFeature;

exports.assertCanPurchasePlan = async (userId, paket) => {
  const targetPlan = getPlan(paket);
  if (targetPlan.paket === "free") {
    throwError("Paket tidak valid untuk pembayaran", 400, "SUBSCRIPTION_PLAN_INVALID");
  }

  const entitlements = await exports.getEntitlements(userId);
  const currentPlan = getPlan(entitlements.paket);
  const minimumRank = currentPlan.rank === 0 ? 1 : currentPlan.rank;

  if (targetPlan.rank < minimumRank) {
    throwError(
      "Pilih paket yang sama atau lebih tinggi untuk memperpanjang",
      400,
      "SUBSCRIPTION_PLAN_NOT_UPGRADE"
    );
  }
};

exports.assertLaporanRange = async (userId, query = {}) => {
  const entitlements = await exports.getEntitlements(userId);
  if (entitlements.features.laporan_keuangan !== "bulan_ini") {
    return entitlements;
  }

  const bulanIni = currentMonthKey();
  if (query.bulan_mulai !== bulanIni || query.bulan_akhir !== bulanIni) {
    throwError(
      "Paket Free hanya bisa melihat laporan bulan ini",
      403,
      "SUBSCRIPTION_REPORT_RANGE_LOCKED"
    );
  }

  return entitlements;
};

async function kirimReminderSubscription(subscription, jenis, title, body) {
  try {
    const result = await FcmService.sendToUser(subscription.user_id, {
      title,
      body,
      data: {
        type: "subscription_reminder",
        reminder: jenis,
        paket: subscription.paket,
        subscription_id: subscription.id,
        expired_at: subscription.expired_at,
        grace_until: subscription.grace_until,
      },
    });

    return result.sent > 0 ? "sent" : "skipped";
  } catch (error) {
    console.error("[subscription:reminder] gagal", {
      user_id: subscription.user_id,
      subscription_id: subscription.id,
      reminder: jenis,
      error: error?.message || error,
    });
    return "failed";
  }
}

exports.sendSubscriptionReminders = async (tanggal = new Date()) => {
  const now = new Date(tanggal);
  const subscriptions = await UserSubscription.findAll({
    where: {
      status: { [Op.in]: ["active", "past_due", "expired"] },
      expired_at: { [Op.ne]: null },
    },
  });

  const result = {
    checked: subscriptions.length,
    sent: 0,
    skipped: 0,
    failed: 0,
  };

  for (const subscription of subscriptions) {
    let reminder = null;
    let title = null;
    let body = null;

    const daysToExpired = selisihHari(subscription.expired_at, now);
    const daysAfterExpired = -daysToExpired;

    if (subscription.status === "active" && REMINDER_BEFORE_EXPIRED.has(daysToExpired)) {
      reminder = `before_h${daysToExpired}`;
      title = "Langganan akan berakhir";
      body = `Paket ${subscription.paket} akan berakhir dalam ${daysToExpired} hari.`;
    } else if (subscription.status === "past_due" && daysAfterExpired === 0) {
      reminder = "expired_today";
      title = "Langganan masuk masa tenggang";
      body = `Paket ${subscription.paket} sudah habis. Masa tenggang 10 hari dimulai.`;
    } else if (
      subscription.status === "past_due" &&
      REMINDER_AFTER_EXPIRED.has(daysAfterExpired)
    ) {
      reminder = `after_h${daysAfterExpired}`;
      title =
        daysAfterExpired >= GRACE_PERIOD_DAYS
          ? "Fitur premium terkunci"
          : "Masa tenggang langganan";
      body =
        daysAfterExpired >= GRACE_PERIOD_DAYS
          ? "Masa tenggang habis. Fitur premium terkunci sampai bayar ulang."
          : `Masa tenggang paket ${subscription.paket} tersisa ${
              GRACE_PERIOD_DAYS - daysAfterExpired
            } hari.`;
    } else if (
      subscription.status === "expired" &&
      daysAfterExpired === GRACE_PERIOD_DAYS
    ) {
      reminder = "after_grace_locked";
      title = "Fitur premium terkunci";
      body = "Masa tenggang habis. Fitur premium terkunci sampai bayar ulang.";
    }

    if (!reminder) {
      result.skipped += 1;
      continue;
    }

    const status = await kirimReminderSubscription(subscription, reminder, title, body);
    result[status] += 1;
  }

  return result;
};

exports.syncSubscriptionLifecycle = async () => {
  const transition = await exports.refreshSubscriptionStatuses();
  const reminders = await exports.sendSubscriptionReminders();

  return {
    ...transition,
    reminders,
  };
};

exports.filterDashboardByPlan = (data, entitlements) => {
  if (entitlements.features.dashboard !== "dasar") return data;

  return {
    pemilik: data.pemilik,
    periode: data.periode,
    ringkasan: data.ringkasan,
    pendapatan: {
      bulan_ini: data.pendapatan?.bulan_ini || 0,
    },
  };
};
