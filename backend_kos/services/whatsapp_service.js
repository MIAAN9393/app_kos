require("../model/index")

const WhatsAppIntegration = require("../model/whatsapp_integration")
const WhatsAppAutoSendSetting = require("../model/whatsapp_auto_send_setting")
const WhatsAppSettingsResponse = require("../response/whatsapp_response")
const { validasiWhatsappSettings } = require("../validator/whatsapp_validator")
const { throwError } = require("../utils/error")
const { validateWhatsAppNumber } = require("../utils/phone_helper")
const whatsappCloudService = require("./whatsapp_cloud_service")
const whatsappMessageLogService = require("./whatsapp_message_log_service")
const invoicePdfService = require("./invoice_pdf_service")
const kontrakPdfService = require("./kontrak_pdf_service")

function getStatus(phoneNumberId, accessToken) {
  return phoneNumberId && accessToken ? "connected" : "disconnected"
}

async function ambilAtauBuatAutoSend(userId) {
  const [row] = await WhatsAppAutoSendSetting.findOrCreate({
    where: { user_id: userId },
    defaults: { user_id: userId },
  })

  return row
}

exports.ambilSettings = async (pemilik_id) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  const integration = await WhatsAppIntegration.findOne({
    where: { user_id: pemilik_id },
  })
  const autoSend = await ambilAtauBuatAutoSend(pemilik_id)

  return new WhatsAppSettingsResponse(integration, autoSend)
}

exports.simpanSettings = async (pemilik_id, body) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  const integrationLama = await WhatsAppIntegration.findOne({
    where: { user_id: pemilik_id },
  })
  const autoSendLama = await ambilAtauBuatAutoSend(pemilik_id)
  const hasilValidasi = validasiWhatsappSettings(body, autoSendLama)
  const integrationBody = body.integration || body
  const adaPhoneNumberId = Object.prototype.hasOwnProperty.call(
    integrationBody,
    "phone_number_id"
  )
  const adaAccessToken = Object.prototype.hasOwnProperty.call(
    integrationBody,
    "access_token"
  )
  const phone_number_id = adaPhoneNumberId
    ? hasilValidasi.integration.phone_number_id
    : integrationLama?.phone_number_id || null
  const accessTokenBaru = hasilValidasi.integration.access_token
  const access_token = adaAccessToken && accessTokenBaru
    ? accessTokenBaru
    : integrationLama?.access_token || null
  const accessTokenChanged = adaAccessToken && accessTokenBaru
    ? accessTokenBaru !== integrationLama?.access_token
    : false
  const credentialsChanged =
    (adaPhoneNumberId && phone_number_id !== integrationLama?.phone_number_id) ||
    accessTokenChanged
  const status = credentialsChanged
    ? "disconnected"
    : integrationLama?.status || getStatus(phone_number_id, access_token)

  const [integration] = await WhatsAppIntegration.findOrCreate({
    where: { user_id: pemilik_id },
    defaults: {
      user_id: pemilik_id,
      phone_number_id,
      access_token,
      status,
    },
  })

  await integration.update({
    phone_number_id,
    access_token,
    status,
  })

  await autoSendLama.update(hasilValidasi.auto_send)

  return new WhatsAppSettingsResponse(integration, autoSendLama)
}

exports.tesKoneksi = async (pemilik_id) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  const integration = await WhatsAppIntegration.findOne({
    where: { user_id: pemilik_id },
  })

  if (!integration?.phone_number_id || !integration?.access_token) {
    throwError(
      "Phone Number ID dan Access Token wajib diisi",
      400,
      "WHATSAPP_CONFIG_INCOMPLETE"
    )
  }

  try {
    const result = await whatsappCloudService.testConnection({
      phone_number_id: integration.phone_number_id,
      access_token: integration.access_token,
    })

    await integration.update({ status: "connected" })

    return {
      ...result,
      pesan: "Koneksi WhatsApp berhasil.",
    }
  } catch (error) {
    await integration.update({ status: "disconnected" })
    throw error
  }
}

exports.kirimPesanTest = async (pemilik_id, body = {}) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  const integration = await WhatsAppIntegration.findOne({
    where: { user_id: pemilik_id },
  })

  if (!integration?.phone_number_id || !integration?.access_token) {
    throwError(
      "Phone Number ID dan Access Token wajib diisi",
      400,
      "WHATSAPP_CONFIG_INCOMPLETE"
    )
  }

  const to = validateWhatsAppNumber(body.to)
  if (!to) {
    throwError("Nomor tujuan wajib diisi", 400, "WHATSAPP_TO_REQUIRED")
  }
  const message = String(body.message || "").trim()
  if (!message) {
    throwError("Pesan wajib diisi", 400, "WHATSAPP_MESSAGE_REQUIRED")
  }

  const log = await whatsappMessageLogService.createPendingLog({
    user_id: pemilik_id,
    no_tujuan: to,
    tipe: "test",
  })

  let result
  try {
    result = await whatsappCloudService.sendTextMessage({
      phone_number_id: integration.phone_number_id,
      access_token: integration.access_token,
      to,
      message,
    })
    await whatsappMessageLogService.markLogSent(log, result.message_id)
  } catch (error) {
    await whatsappMessageLogService.markLogFailed(log, error)
    throw error
  }

  return {
    ...result,
    pesan: "Pesan test WhatsApp berhasil dikirim.",
  }
}

exports.ambilMessageLogs = async (pemilik_id, query = {}) => {
  return whatsappMessageLogService.getLogsByUser(pemilik_id, query)
}

async function kirimInvoiceTagihanToWhatsApp({
  user_id,
  tagihan_id,
  skipIfSent = false,
}) {
  if (!user_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  if (!tagihan_id) {
    throwError("Tagihan tidak ditemukan", 400, "TAGIHAN_NOT_FOUND")
  }

  if (
    skipIfSent &&
    (await whatsappMessageLogService.hasSentInvoiceLog(user_id, tagihan_id))
  ) {
    return {
      status: "skipped",
      pesan: "Invoice WhatsApp sudah pernah terkirim.",
    }
  }

  const integration = await WhatsAppIntegration.findOne({
    where: { user_id },
  })

  if (!integration) {
    throwError(
      "Integrasi WhatsApp belum dikonfigurasi.",
      400,
      "WHATSAPP_NOT_CONFIGURED"
    )
  }

  if (!integration.phone_number_id) {
    throwError(
      "Phone Number ID belum tersimpan.",
      400,
      "WHATSAPP_PHONE_NUMBER_ID_REQUIRED"
    )
  }

  if (!integration.access_token) {
    throwError(
      "Access token belum tersimpan.",
      400,
      "WHATSAPP_ACCESS_TOKEN_REQUIRED"
    )
  }

  let invoice
  try {
    invoice = await invoicePdfService.generateInvoicePdfBuffer(tagihan_id, user_id)
  } catch (error) {
    if (error.code === "TAGIHAN_NOT_FOUND") throw error
    throwError("Gagal generate PDF invoice.", 500, "INVOICE_PDF_FAILED")
  }

  const { data } = invoice
  const penyewa = data.penyewa
  const tagihan = data.tagihan
  let to
  try {
    to = validateWhatsAppNumber(penyewa.no_telpon)
  } catch (error) {
    const log = await whatsappMessageLogService.createPendingLog({
      user_id,
      tagihan_id: tagihan.id,
      penyewa_id: penyewa.id,
      no_tujuan: penyewa.no_telpon || "-",
      tipe: "invoice",
    })
    await whatsappMessageLogService.markLogFailed(log, error)
    throw error
  }

  if (!to) {
    const log = await whatsappMessageLogService.createPendingLog({
      user_id,
      tagihan_id: tagihan.id,
      penyewa_id: penyewa.id,
      no_tujuan: "-",
      tipe: "invoice",
    })
    await whatsappMessageLogService.markLogFailed(
      log,
      new Error("Nomor WhatsApp penyewa belum tersedia.")
    )
    throwError(
      "Nomor WhatsApp penyewa belum tersedia.",
      400,
      "PENYEWA_WHATSAPP_MISSING"
    )
  }

  const log = await whatsappMessageLogService.createPendingLog({
    user_id,
    tagihan_id: tagihan.id,
    penyewa_id: penyewa.id,
    no_tujuan: to,
    tipe: "invoice",
  })

  try {
    const media = await whatsappCloudService.uploadDocumentMedia({
      phone_number_id: integration.phone_number_id,
      access_token: integration.access_token,
      buffer: invoice.buffer,
      filename: invoice.filename,
      mime_type: "application/pdf",
    })

    const caption = `Halo ${penyewa.nama}, berikut invoice tagihan ${tagihan.kode_tagihan}. Total: ${invoicePdfService.formatRupiah(tagihan.total_tagihan)}. Sisa bayar: ${invoicePdfService.formatRupiah(data.sisaBayar)}. Terima kasih.`

    const result = await whatsappCloudService.sendDocumentMessage({
      phone_number_id: integration.phone_number_id,
      access_token: integration.access_token,
      to,
      media_id: media.media_id,
      filename: invoice.filename,
      caption,
    })

    await whatsappMessageLogService.markLogSent(log, result.message_id)

    return {
      ...result,
      filename: invoice.filename,
      pesan: "Invoice berhasil dikirim ke WhatsApp.",
    }
  } catch (error) {
    await whatsappMessageLogService.markLogFailed(log, error)
    throw error
  }
}

exports.kirimInvoiceTagihan = async (pemilik_id, tagihan_id) => {
  return kirimInvoiceTagihanToWhatsApp({
    user_id: pemilik_id,
    tagihan_id,
    skipIfSent: false,
  })
}

exports.kirimInvoiceTagihanOtomatisSaatCreate = async (pemilik_id, tagihan_id) => {
  try {
    const autoSend = await WhatsAppAutoSendSetting.findOne({
      where: { user_id: pemilik_id },
    })

    if (!autoSend?.auto_send_tagihan_on_create) {
      return {
        whatsapp_invoice_status: "skipped",
        whatsapp_invoice_message: "Pengiriman invoice otomatis tidak aktif.",
      }
    }

    const integration = await WhatsAppIntegration.findOne({
      where: { user_id: pemilik_id },
    })

    if (
      !integration?.phone_number_id ||
      !integration?.access_token ||
      integration.status !== "connected"
    ) {
      return {
        whatsapp_invoice_status: "failed",
        whatsapp_invoice_message: "Integrasi WhatsApp belum terhubung.",
      }
    }

    const result = await kirimInvoiceTagihanToWhatsApp({
      user_id: pemilik_id,
      tagihan_id,
      skipIfSent: true,
    })

    return {
      whatsapp_invoice_status: result.status === "skipped" ? "skipped" : "sent",
      whatsapp_invoice_message: result.pesan || "Invoice otomatis dikirim.",
    }
  } catch (error) {
    return {
      whatsapp_invoice_status: "failed",
      whatsapp_invoice_message:
        error?.message || "Invoice WhatsApp gagal dikirim.",
    }
  }
}

exports.kirimInvoiceTagihanOtomatisDariCron = async (pemilik_id, tagihan_id) => {
  try {
    const autoSend = await WhatsAppAutoSendSetting.findOne({
      where: { user_id: pemilik_id },
    })

    if (!autoSend?.auto_send_tagihan_from_cron) {
      return {
        whatsapp_invoice_status: "skipped",
        whatsapp_invoice_message: "Pengiriman invoice dari cron tidak aktif.",
      }
    }

    const integration = await WhatsAppIntegration.findOne({
      where: { user_id: pemilik_id },
    })

    if (
      !integration?.phone_number_id ||
      !integration?.access_token ||
      integration.status !== "connected"
    ) {
      return {
        whatsapp_invoice_status: "failed",
        whatsapp_invoice_message: "Integrasi WhatsApp belum terhubung.",
      }
    }

    const result = await kirimInvoiceTagihanToWhatsApp({
      user_id: pemilik_id,
      tagihan_id,
      skipIfSent: true,
    })

    return {
      whatsapp_invoice_status: result.status === "skipped" ? "skipped" : "sent",
      whatsapp_invoice_message: result.pesan || "Invoice dari cron dikirim.",
    }
  } catch (error) {
    return {
      whatsapp_invoice_status: "failed",
      whatsapp_invoice_message:
        error?.message || "Invoice WhatsApp dari cron gagal dikirim.",
    }
  }
}

async function ambilIntegrationSiap(user_id) {
  const integration = await WhatsAppIntegration.findOne({
    where: { user_id },
  })

  if (!integration) {
    throwError(
      "Integrasi WhatsApp belum dikonfigurasi.",
      400,
      "WHATSAPP_NOT_CONFIGURED"
    )
  }

  if (!integration.phone_number_id) {
    throwError(
      "Phone Number ID belum tersimpan.",
      400,
      "WHATSAPP_PHONE_NUMBER_ID_REQUIRED"
    )
  }

  if (!integration.access_token) {
    throwError(
      "Access token belum tersimpan.",
      400,
      "WHATSAPP_ACCESS_TOKEN_REQUIRED"
    )
  }

  if (integration.status !== "connected") {
    throwError(
      "Integrasi WhatsApp belum terhubung.",
      400,
      "WHATSAPP_NOT_CONNECTED"
    )
  }

  return integration
}

async function kirimKontrakToWhatsApp({
  user_id,
  kontrak_id,
  skipIfSent = false,
}) {
  if (!user_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  if (!kontrak_id) {
    throwError("Kontrak tidak ditemukan", 400, "KONTRAK_NOT_FOUND")
  }

  if (
    skipIfSent &&
    (await whatsappMessageLogService.hasSentKontrakLog(user_id, kontrak_id))
  ) {
    return {
      status: "skipped",
      pesan: "Kontrak WhatsApp sudah pernah terkirim.",
    }
  }

  const integration = await ambilIntegrationSiap(user_id)

  let kontrakPdf
  try {
    kontrakPdf = await kontrakPdfService.generateKontrakPdfBuffer(
      kontrak_id,
      user_id
    )
  } catch (error) {
    if (error.code === "KONTRAK_NOT_FOUND") throw error
    throwError("Gagal generate PDF kontrak.", 500, "KONTRAK_PDF_FAILED")
  }

  const { data } = kontrakPdf
  const penyewa = data.penyewa
  const kontrak = data.kontrak
  let to
  try {
    to = validateWhatsAppNumber(penyewa.no_telpon)
  } catch (error) {
    const log = await whatsappMessageLogService.createPendingLog({
      user_id,
      kontrak_id: kontrak.id,
      penyewa_id: penyewa.id,
      no_tujuan: penyewa.no_telpon || "-",
      tipe: "kontrak",
    })
    await whatsappMessageLogService.markLogFailed(log, error)
    throw error
  }

  if (!to) {
    const log = await whatsappMessageLogService.createPendingLog({
      user_id,
      kontrak_id: kontrak.id,
      penyewa_id: penyewa.id,
      no_tujuan: "-",
      tipe: "kontrak",
    })
    await whatsappMessageLogService.markLogFailed(
      log,
      new Error("Nomor WhatsApp penyewa belum tersedia.")
    )
    throwError(
      "Nomor WhatsApp penyewa belum tersedia.",
      400,
      "PENYEWA_WHATSAPP_MISSING"
    )
  }

  const log = await whatsappMessageLogService.createPendingLog({
    user_id,
    kontrak_id: kontrak.id,
    penyewa_id: penyewa.id,
    no_tujuan: to,
    tipe: "kontrak",
  })

  try {
    const media = await whatsappCloudService.uploadDocumentMedia({
      phone_number_id: integration.phone_number_id,
      access_token: integration.access_token,
      buffer: kontrakPdf.buffer,
      filename: kontrakPdf.filename,
      mime_type: "application/pdf",
    })

    const caption = `Halo ${penyewa.nama}, berikut detail kontrak ${kontrak.kode_kontrak || `#${kontrak.id}`}. Terima kasih.`

    const result = await whatsappCloudService.sendDocumentMessage({
      phone_number_id: integration.phone_number_id,
      access_token: integration.access_token,
      to,
      media_id: media.media_id,
      filename: kontrakPdf.filename,
      caption,
    })

    await whatsappMessageLogService.markLogSent(log, result.message_id)

    return {
      ...result,
      filename: kontrakPdf.filename,
      pesan: "Kontrak berhasil dikirim ke WhatsApp.",
    }
  } catch (error) {
    await whatsappMessageLogService.markLogFailed(log, error)
    throw error
  }
}

exports.kirimKontrak = async (pemilik_id, kontrak_id) => {
  return kirimKontrakToWhatsApp({
    user_id: pemilik_id,
    kontrak_id,
    skipIfSent: false,
  })
}

exports.kirimKontrakOtomatisSaatCreate = async (pemilik_id, kontrak_id) => {
  try {
    const autoSend = await WhatsAppAutoSendSetting.findOne({
      where: { user_id: pemilik_id },
    })

    if (!autoSend?.auto_send_penyewa_contract_on_create) {
      return {
        whatsapp_kontrak_status: "skipped",
        whatsapp_kontrak_message: "Pengiriman kontrak otomatis tidak aktif.",
      }
    }

    const result = await kirimKontrakToWhatsApp({
      user_id: pemilik_id,
      kontrak_id,
      skipIfSent: true,
    })

    return {
      whatsapp_kontrak_status: result.status === "skipped" ? "skipped" : "sent",
      whatsapp_kontrak_message: result.pesan || "Kontrak otomatis dikirim.",
    }
  } catch (error) {
    return {
      whatsapp_kontrak_status: "failed",
      whatsapp_kontrak_message:
        error?.message || "Kontrak WhatsApp gagal dikirim.",
    }
  }
}

exports.kirimReminderKontrakSebelumSelesai = async ({
  user_id,
  kontrak,
  penyewa,
  kamar,
  kos,
  today,
}) => {
  try {
    const autoSend = await WhatsAppAutoSendSetting.findOne({
      where: { user_id },
    })

    if (!autoSend?.auto_send_penyewa_reminder_before_contract_end) {
      return { status: "skipped" }
    }

    if (
      await whatsappMessageLogService.hasSentReminderLogToday(
        user_id,
        kontrak.id,
        today
      )
    ) {
      return { status: "skipped" }
    }

    const log = await whatsappMessageLogService.createPendingLog({
      user_id,
      kontrak_id: kontrak.id,
      penyewa_id: penyewa.id,
      no_tujuan: penyewa.no_telpon || "-",
      tipe: "reminder",
    })

    try {
      const integration = await ambilIntegrationSiap(user_id)
      const to = validateWhatsAppNumber(penyewa.no_telpon)
      if (!to) {
        throwError(
          "Nomor WhatsApp penyewa belum tersedia.",
          400,
          "PENYEWA_WHATSAPP_MISSING"
        )
      }

      if (log.no_tujuan !== to) {
        await log.update({ no_tujuan: to })
      }

      const tanggalSelesai = kontrakPdfService.formatTanggal(
        kontrak.tanggal_selesai
      )
      const message = `Halo ${penyewa.nama}, kontrak sewa kamar ${kamar.nomor} di ${kos.nama_kos} akan berakhir pada ${tanggalSelesai}. Silakan hubungi pemilik kos untuk perpanjangan. Terima kasih.`

      const result = await whatsappCloudService.sendTextMessage({
        phone_number_id: integration.phone_number_id,
        access_token: integration.access_token,
        to,
        message,
      })
      await whatsappMessageLogService.markLogSent(log, result.message_id)
      return { status: "sent" }
    } catch (error) {
      await whatsappMessageLogService.markLogFailed(log, error)
      return { status: "failed", message: error?.message }
    }
  } catch (error) {
    return { status: "failed", message: error?.message }
  }
}
