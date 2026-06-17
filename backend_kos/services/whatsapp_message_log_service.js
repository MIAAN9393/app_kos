require("../model/index")

const { Op } = require("sequelize")
const WhatsAppMessageLog = require("../model/whatsapp_message_log")
const { throwError } = require("../utils/error")

const TIPE_VALID = ["test", "invoice", "kontrak", "reminder"]
const STATUS_VALID = ["pending", "sent", "failed"]

function nullableId(value) {
  if (value === undefined || value === null || value === "") return null
  const id = Number(value)
  if (!Number.isInteger(id) || id <= 0) {
    throwError("filter log WhatsApp tidak valid", 400, "INVALID_WHATSAPP_LOG_FILTER")
  }
  return id
}

function sanitizeErrorMessage(error) {
  const message = `${error?.message || error || "Gagal mengirim pesan WhatsApp."}`
  return message.replace(/Bearer\s+[A-Za-z0-9._-]+/g, "Bearer [hidden]")
}

function logResponse(row) {
  const data = typeof row?.get === "function" ? row.get({ plain: true }) : row
  if (!data) return null

  return {
    id: data.id,
    user_id: data.user_id,
    tagihan_id: data.tagihan_id,
    kontrak_id: data.kontrak_id,
    penyewa_id: data.penyewa_id,
    no_tujuan: data.no_tujuan,
    tipe: data.tipe,
    status: data.status,
    wa_message_id: data.wa_message_id,
    error_message: data.error_message,
    created_at: data.created_at,
    updated_at: data.updated_at,
  }
}

exports.createPendingLog = async ({
  user_id,
  tagihan_id = null,
  kontrak_id = null,
  penyewa_id = null,
  no_tujuan,
  tipe,
}) => {
  if (!user_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  if (!no_tujuan) {
    throwError("Nomor tujuan wajib diisi", 400, "WHATSAPP_TO_REQUIRED")
  }

  if (!TIPE_VALID.includes(tipe)) {
    throwError("Tipe log WhatsApp tidak valid", 400, "INVALID_WHATSAPP_LOG_TYPE")
  }

  const row = await WhatsAppMessageLog.create({
    user_id,
    tagihan_id,
    kontrak_id,
    penyewa_id,
    no_tujuan,
    tipe,
    status: "pending",
  })

  return row
}

exports.markLogSent = async (log, wa_message_id = null) => {
  if (!log) return null
  await log.update({
    status: "sent",
    wa_message_id,
    error_message: null,
  })
  return logResponse(log)
}

exports.markLogFailed = async (log, error) => {
  if (!log) return null
  await log.update({
    status: "failed",
    error_message: sanitizeErrorMessage(error),
  })
  return logResponse(log)
}

exports.getLogsByUser = async (user_id, filters = {}) => {
  if (!user_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  const where = { user_id }

  const tagihanId = nullableId(filters.tagihan_id)
  const kontrakId = nullableId(filters.kontrak_id)
  const penyewaId = nullableId(filters.penyewa_id)

  if (tagihanId) where.tagihan_id = tagihanId
  if (kontrakId) where.kontrak_id = kontrakId
  if (penyewaId) where.penyewa_id = penyewaId

  if (filters.tipe) {
    if (!TIPE_VALID.includes(filters.tipe)) {
      throwError("Tipe log WhatsApp tidak valid", 400, "INVALID_WHATSAPP_LOG_TYPE")
    }
    where.tipe = filters.tipe
  }

  if (filters.status) {
    if (!STATUS_VALID.includes(filters.status)) {
      throwError(
        "Status log WhatsApp tidak valid",
        400,
        "INVALID_WHATSAPP_LOG_STATUS"
      )
    }
    where.status = filters.status
  }

  const rows = await WhatsAppMessageLog.findAll({
    where,
    order: [["id", "DESC"]],
    limit: 50,
  })

  return rows.map(logResponse)
}

exports.getLogsByTagihan = (user_id, tagihan_id) =>
  exports.getLogsByUser(user_id, { tagihan_id })

exports.getLogsByKontrak = (user_id, kontrak_id) =>
  exports.getLogsByUser(user_id, { kontrak_id })

exports.getLogsByPenyewa = (user_id, penyewa_id) =>
  exports.getLogsByUser(user_id, { penyewa_id })

exports.hasSentInvoiceLog = async (user_id, tagihan_id) => {
  if (!user_id || !tagihan_id) return false

  const count = await WhatsAppMessageLog.count({
    where: {
      user_id,
      tagihan_id,
      tipe: "invoice",
      status: "sent",
    },
  })

  return count > 0
}

exports.hasSentKontrakLog = async (user_id, kontrak_id) => {
  if (!user_id || !kontrak_id) return false

  const count = await WhatsAppMessageLog.count({
    where: {
      user_id,
      kontrak_id,
      tipe: "kontrak",
      status: "sent",
    },
  })

  return count > 0
}

exports.hasSentReminderLogToday = async (user_id, kontrak_id, today) => {
  if (!user_id || !kontrak_id || !today) return false

  const start = new Date(`${today}T00:00:00+07:00`)
  const end = new Date(start)
  end.setDate(end.getDate() + 1)

  const count = await WhatsAppMessageLog.count({
    where: {
      user_id,
      kontrak_id,
      tipe: "reminder",
      status: "sent",
      created_at: {
        [Op.gte]: start,
        [Op.lt]: end,
      },
    },
  })

  return count > 0
}
