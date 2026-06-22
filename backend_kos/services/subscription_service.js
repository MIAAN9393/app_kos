require("../model/index");

const { Op } = require("sequelize");
const Kos = require("../model/kos");
const Kamar = require("../model/kamar");
const Penyewa = require("../model/penyewa");
const UserSubscription = require("../model/user_subscription");
const { getPlan } = require("../config/subscription_plans");
const { throwError } = require("../utils/error");

const DEFAULT_DURATION_DAYS = 30;

function tambahHari(date, days) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
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

exports.getActiveSubscription = async (userId) => {
  const now = new Date();
  return UserSubscription.findOne({
    where: {
      user_id: userId,
      status: "active",
      [Op.or]: [{ expired_at: null }, { expired_at: { [Op.gt]: now } }],
    },
    order: [["expired_at", "DESC"], ["id", "DESC"]],
  });
};

exports.getEntitlements = async (userId) => {
  const subscription = await exports.getActiveSubscription(userId);
  const plan = getPlan(subscription?.paket || "free");

  return {
    paket: plan.paket,
    subscription,
    limits: plan.limits,
    features: plan.features,
  };
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
  const plan = getPlan(paket);
  const now = new Date();
  const expiredAt = plan.paket === "free" ? null : tambahHari(now, durationDays);

  await UserSubscription.update(
    { status: "expired" },
    {
      where: {
        user_id: userId,
        status: "active",
      },
    }
  );

  return UserSubscription.create({
    user_id: userId,
    paket: plan.paket,
    status: "active",
    source_payment_id: sourcePaymentId,
    started_at: now,
    expired_at: expiredAt,
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

exports.assertCanPurchasePlan = async (userId, paket) => {
  const targetPlan = getPlan(paket);
  if (targetPlan.paket === "free") {
    throwError("Paket tidak valid untuk pembayaran", 400, "SUBSCRIPTION_PLAN_INVALID");
  }

  const entitlements = await exports.getEntitlements(userId);
  const currentPlan = getPlan(entitlements.paket);
  if (targetPlan.rank <= currentPlan.rank) {
    throwError(
      "Pilih paket yang lebih tinggi dari paket aktif saat ini",
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
