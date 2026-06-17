const FcmService = require("../services/fcm_service")
const FcmSettingService = require("../services/fcm_notification_setting_service")

exports.registerToken = async (req, res, next) => {
  try {
    await FcmService.registerToken(req.user.id, req.body || {})
    res.status(200).json({
      success: true,
      pesan: "token notifikasi berhasil disimpan",
    })
  } catch (error) {
    next(error)
  }
}

exports.unregisterToken = async (req, res, next) => {
  try {
    await FcmService.unregisterToken(req.user.id, req.body?.token)
    res.status(200).json({
      success: true,
      pesan: "token notifikasi berhasil dinonaktifkan",
    })
  } catch (error) {
    next(error)
  }
}

exports.testSend = async (req, res, next) => {
  try {
    if (process.env.NODE_ENV === "production") {
      return res.status(403).json({
        success: false,
        pesan: "test FCM hanya tersedia di development",
      })
    }

    const result = await FcmService.sendToUser(req.user.id, {
      title: req.body?.title || "Tes Notifikasi Kos",
      body: req.body?.body || "FCM berhasil dikirim ke perangkat login.",
      data: {
        type: "fcm_test",
      },
    })

    res.status(200).json({
      success: true,
      pesan: "test FCM selesai diproses",
      data: result,
    })
  } catch (error) {
    next(error)
  }
}

exports.ambilSettings = async (req, res, next) => {
  try {
    const data = await FcmSettingService.ambilSettings(req.user.id)
    res.status(200).json({
      success: true,
      pesan: "pengaturan notifikasi",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.simpanSettings = async (req, res, next) => {
  try {
    const data = await FcmSettingService.simpanSettings(req.user.id, req.body)
    res.status(200).json({
      success: true,
      pesan: "pengaturan notifikasi berhasil disimpan",
      data,
    })
  } catch (error) {
    next(error)
  }
}
