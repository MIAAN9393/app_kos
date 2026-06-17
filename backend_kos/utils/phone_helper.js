const { throwError } = require("./error")

function normalizePhoneNumber(value) {
  if (value === undefined || value === null) return null

  const raw = String(value).trim()
  if (raw === "") return null

  if (!/^[0-9\s()+-]+$/.test(raw)) {
    throwError(
      "nomor WhatsApp hanya boleh berisi angka, spasi, tanda plus, tanda minus, dan kurung",
      400,
      "INVALID_WHATSAPP_NUMBER",
    )
  }

  const digits = raw.replace(/\D/g, "")
  if (!digits) return null

  let normalized
  if (digits.startsWith("08")) {
    normalized = `62${digits.slice(1)}`
  } else if (digits.startsWith("62")) {
    normalized = digits
  } else {
    throwError(
      "nomor WhatsApp harus diawali 08 atau 62",
      400,
      "INVALID_WHATSAPP_NUMBER",
    )
  }

  if (normalized.length < 10 || normalized.length > 15) {
    throwError(
      "nomor WhatsApp harus 10 sampai 15 digit",
      400,
      "INVALID_WHATSAPP_NUMBER",
    )
  }

  return normalized
}

function validateWhatsAppNumber(value) {
  return normalizePhoneNumber(value)
}

function normalizeIndonesianPhoneNumber(value, label = "nomor HP") {
  if (value === undefined || value === null) return null

  const raw = String(value).trim()
  if (raw === "") return null

  if (!/^[0-9\s()+-]+$/.test(raw)) {
    throwError(
      `${label} hanya boleh berisi angka, spasi, tanda plus, tanda minus, dan kurung`,
      400,
      "INVALID_PHONE_NUMBER",
    )
  }

  const digits = raw.replace(/\D/g, "")
  if (!digits) return null

  let normalized
  if (digits.startsWith("08")) {
    normalized = `62${digits.slice(1)}`
  } else if (digits.startsWith("62")) {
    normalized = digits
  } else {
    throwError(`${label} harus diawali 08 atau 62`, 400, "INVALID_PHONE_NUMBER")
  }

  if (normalized.length < 10 || normalized.length > 15) {
    throwError(`${label} harus 10 sampai 15 digit`, 400, "INVALID_PHONE_NUMBER")
  }

  return normalized
}

function validatePhoneNumber(value) {
  return normalizeIndonesianPhoneNumber(value)
}

module.exports = {
  normalizePhoneNumber,
  validateWhatsAppNumber,
  normalizeIndonesianPhoneNumber,
  validatePhoneNumber,
}
