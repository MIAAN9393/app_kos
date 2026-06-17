function toPlain(row) {
  if (!row) return null
  return typeof row.get === "function" ? row.get({ plain: true }) : row
}

class WhatsAppSettingsResponse {
  constructor(integration, autoSend) {
    const integrationRow = toPlain(integration) || {}
    const autoSendRow = toPlain(autoSend) || {}

    this.integration = {
      phone_number_id: integrationRow.phone_number_id || null,
      has_access_token: !!integrationRow.access_token,
      status: integrationRow.status || "disconnected",
    }

    this.auto_send = {
      auto_send_tagihan_on_create: !!autoSendRow.auto_send_tagihan_on_create,
      auto_send_tagihan_from_cron: !!autoSendRow.auto_send_tagihan_from_cron,
      auto_send_tagihan_reminder_before_due:
        !!autoSendRow.auto_send_tagihan_reminder_before_due,
      auto_send_tagihan_reminder_overdue:
        !!autoSendRow.auto_send_tagihan_reminder_overdue,
      auto_send_penyewa_contract_on_create:
        !!autoSendRow.auto_send_penyewa_contract_on_create,
      auto_send_penyewa_contract_from_cron:
        !!autoSendRow.auto_send_penyewa_contract_from_cron,
      auto_send_penyewa_reminder_before_contract_end:
        !!autoSendRow.auto_send_penyewa_reminder_before_contract_end,
    }
  }
}

module.exports = WhatsAppSettingsResponse
