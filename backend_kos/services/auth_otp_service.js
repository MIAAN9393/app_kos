const crypto = require("crypto")
const { Op } = require("sequelize")
const AuthOtp = require("../model/auth_otp")
const User = require("../model/user")
const EmailService = require("./email_service")
const SmsService = require("./sms_service")
const { throwError } = require("../utils/error")

const EXPIRES_MINUTES = 15
const MAX_ATTEMPTS = 5

function normalisasiEmail(email) {
  return `${email ?? ""}`.trim().toLowerCase()
}

function normalisasiPhone(phone) {
  return `${phone ?? ""}`.trim()
}

function buatKode() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, "0")
}

function hashKode(code) {
  return crypto
    .createHash("sha256")
    .update(`${process.env.JWT_SECRET || "secret"}:${code}`)
    .digest("hex")
}

function targetUntukUser(user, channel) {
  if (channel === "phone") {
    return { no_telpon: normalisasiPhone(user.no_telpon), email: null }
  }
  return { email: normalisasiEmail(user.email), no_telpon: null }
}

async function buatOtp({ user, purpose, channel }) {
  const code = buatKode()
  const expiresAt = new Date(Date.now() + EXPIRES_MINUTES * 60 * 1000)
  const target = targetUntukUser(user, channel)

  await AuthOtp.update(
    { used_at: new Date() },
    {
      where: {
        user_id: user.id,
        purpose,
        channel,
        used_at: null,
      },
    }
  )

  await AuthOtp.create({
    user_id: user.id,
    ...target,
    channel,
    purpose,
    code_hash: hashKode(code),
    expires_at: expiresAt,
  })

  return { code, expiresAt }
}

async function kirimKode({ user, purpose, channel }) {
  const { code, expiresAt } = await buatOtp({ user, purpose, channel })
  const isVerify = purpose === "email_verification"
  const isPhone = channel === "phone"

  const delivery = isPhone
    ? await SmsService.kirimOtp({
        to: user.no_telpon,
        title: purpose === "phone_verification" ? "Verifikasi nomor HP" : "Reset password",
        code,
        expiresMinutes: EXPIRES_MINUTES,
      })
    : await EmailService.kirimOtp({
        to: user.email,
        subject: isVerify ? "Verifikasi email Kos Management" : "Reset password Kos Management",
        title: isVerify ? "Verifikasi email" : "Reset password",
        code,
        expiresMinutes: EXPIRES_MINUTES,
      })

  return {
    expires_at: expiresAt,
    delivery: delivery.sent ? "sent" : "not_configured",
    ...(delivery.sent || process.env.NODE_ENV === "production"
      ? {}
      : { dev_otp: code }),
  }
}

async function validasiOtp({ email, phone, code, purpose, channel }) {
  const normalizedEmail = normalisasiEmail(email)
  const normalizedPhone = normalisasiPhone(phone)
  const otpCode = `${code ?? ""}`.trim()

  if ((!normalizedEmail && !normalizedPhone) || !otpCode) {
    throwError("kontak dan kode OTP wajib diisi", 400, "VALIDATION_ERROR")
  }

  const otp = await AuthOtp.findOne({
    where: {
      ...(channel === "phone"
        ? { no_telpon: normalizedPhone }
        : { email: normalizedEmail }),
      channel,
      purpose,
      used_at: null,
      expires_at: { [Op.gt]: new Date() },
    },
    order: [["created_at", "DESC"]],
  })

  if (!otp) {
    throwError("kode OTP tidak valid atau sudah kedaluwarsa", 400, "INVALID_OTP")
  }

  if (otp.attempt_count >= MAX_ATTEMPTS) {
    await otp.update({ used_at: new Date() })
    throwError("percobaan OTP terlalu banyak, minta kode baru", 429, "OTP_TOO_MANY_ATTEMPTS")
  }

  const cocok = otp.code_hash === hashKode(otpCode)
  if (!cocok) {
    await otp.update({ attempt_count: otp.attempt_count + 1 })
    throwError("kode OTP tidak valid", 400, "INVALID_OTP")
  }

  const user = await User.findByPk(otp.user_id)
  if (!user) {
    throwError("user tidak ditemukan", 404, "USER_NOT_FOUND")
  }

  return { otp, user }
}

exports.kirimVerifikasiEmail = async (user) => {
  return kirimKode({ user, purpose: "email_verification", channel: "email" })
}

exports.kirimVerifikasiPhone = async (user) => {
  return kirimKode({ user, purpose: "phone_verification", channel: "phone" })
}

exports.kirimResetPassword = async (user, channel = "email") => {
  return kirimKode({ user, purpose: "password_reset", channel })
}

exports.verifikasiEmail = async ({ email, code }) => {
  const { otp, user } = await validasiOtp({
    email,
    code,
    purpose: "email_verification",
    channel: "email",
  })

  await otp.update({ used_at: new Date() })
  await user.update({
    email_verified: true,
    email_verified_at: new Date(),
  })

  return user
}

exports.verifikasiPhone = async ({ phone, code }) => {
  const { otp, user } = await validasiOtp({
    phone,
    code,
    purpose: "phone_verification",
    channel: "phone",
  })

  await otp.update({ used_at: new Date() })
  await user.update({
    phone_verified: true,
    phone_verified_at: new Date(),
  })

  return user
}

exports.validasiResetPassword = async ({ email, phone, code, channel = "email" }) => {
  return validasiOtp({
    email,
    phone,
    code,
    purpose: "password_reset",
    channel,
  })
}
