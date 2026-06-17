const { throwError } = require("../utils/error")

function nullableString(value) {
  if (value === undefined || value === null) return null
  const text = String(value).trim()
  return text === "" ? null : text
}

function boolValue(value, fallback = false) {
  if (value === undefined || value === null) return fallback
  if (typeof value === "boolean") return value
  if (value === 1 || value === "1" || value === "true") return true
  if (value === 0 || value === "0" || value === "false") return false
  throwError("setting WhatsApp harus bernilai true atau false", 400, "INVALID_WHATSAPP_SETTING")
}

exports.validasiWhatsappSettings = (body = {}, existingAutoSend = {}) => {
  const integration = body.integration || body
  const autoSend = body.auto_send || body.autoSend || {}

  const phone_number_id = nullableString(integration.phone_number_id)
  const access_token = nullableString(integration.access_token)

  return {
    integration: {
      phone_number_id,
      access_token,
    },
    auto_send: {
      auto_send_tagihan_on_create: boolValue(
        autoSend.auto_send_tagihan_on_create,
        !!existingAutoSend.auto_send_tagihan_on_create
      ),
      auto_send_tagihan_from_cron: boolValue(
        autoSend.auto_send_tagihan_from_cron,
        !!existingAutoSend.auto_send_tagihan_from_cron
      ),
      auto_send_tagihan_reminder_before_due: boolValue(
        autoSend.auto_send_tagihan_reminder_before_due,
        !!existingAutoSend.auto_send_tagihan_reminder_before_due
      ),
      auto_send_tagihan_reminder_overdue: boolValue(
        autoSend.auto_send_tagihan_reminder_overdue,
        !!existingAutoSend.auto_send_tagihan_reminder_overdue
      ),
      auto_send_penyewa_contract_on_create: boolValue(
        autoSend.auto_send_penyewa_contract_on_create,
        !!existingAutoSend.auto_send_penyewa_contract_on_create
      ),
      auto_send_penyewa_contract_from_cron: boolValue(
        autoSend.auto_send_penyewa_contract_from_cron,
        !!existingAutoSend.auto_send_penyewa_contract_from_cron
      ),
      auto_send_penyewa_reminder_before_contract_end: boolValue(
        autoSend.auto_send_penyewa_reminder_before_contract_end,
        !!existingAutoSend.auto_send_penyewa_reminder_before_contract_end
      ),
    },
  }
}
