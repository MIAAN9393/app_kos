const WhatsAppService = require("../services/whatsapp_service")

exports.ambilSettings = async (req, res, next) => {
  try {
    const data = await WhatsAppService.ambilSettings(req.user.id)

    res.status(200).json({
      success: true,
      code: "WHATSAPP_SETTINGS_SUCCESS",
      pesan: "pengaturan WhatsApp berhasil diambil",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.simpanSettings = async (req, res, next) => {
  try {
    const data = await WhatsAppService.simpanSettings(req.user.id, req.body)

    res.status(200).json({
      success: true,
      code: "WHATSAPP_SETTINGS_UPDATED",
      pesan: "pengaturan WhatsApp berhasil disimpan",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.tesKoneksi = async (req, res, next) => {
  try {
    const data = await WhatsAppService.tesKoneksi(req.user.id)

    res.status(200).json({
      success: true,
      code: "WHATSAPP_CONNECTION_READY",
      pesan: "tes koneksi WhatsApp siap",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.kirimPesanTest = async (req, res, next) => {
  try {
    const data = await WhatsAppService.kirimPesanTest(req.user.id, req.body)

    res.status(200).json({
      success: true,
      code: "WHATSAPP_TEST_MESSAGE_SENT",
      pesan: "pesan test WhatsApp berhasil dikirim",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.ambilMessageLogs = async (req, res, next) => {
  try {
    const data = await WhatsAppService.ambilMessageLogs(req.user.id, req.query)

    res.status(200).json({
      success: true,
      code: "WHATSAPP_MESSAGE_LOGS_SUCCESS",
      pesan: "riwayat pengiriman WhatsApp berhasil diambil",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.kirimInvoiceTagihan = async (req, res, next) => {
  try {
    const data = await WhatsAppService.kirimInvoiceTagihan(
      req.user.id,
      req.params.tagihan_id
    )

    res.status(200).json({
      success: true,
      code: "WHATSAPP_INVOICE_SENT",
      pesan: "Invoice berhasil dikirim ke WhatsApp.",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.kirimKontrak = async (req, res, next) => {
  try {
    const data = await WhatsAppService.kirimKontrak(
      req.user.id,
      req.params.kontrak_id
    )

    res.status(200).json({
      success: true,
      code: "WHATSAPP_KONTRAK_SENT",
      pesan: "Kontrak berhasil dikirim ke WhatsApp.",
      data,
    })
  } catch (error) {
    next(error)
  }
}
