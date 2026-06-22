const tagihanOtomatisService = require("../services/pengaturan_tagihan_otomatis_service")
const perpanjanganOtomatisService = require("../services/pengaturan_perpanjangan_kontrak_otomatis_service")
const SubscriptionService = require("../services/subscription_service")

exports.ambil_tagihan_otomatis = async (req, res, next) => {
  try {
    await SubscriptionService.assertFeature(req.user.id, "tagihan_otomatis")

    const data = await tagihanOtomatisService.ambilPengaturanTagihanOtomatis(
      req.user.id,
      req.params.kontrak_id
    )

    res.status(200).json({
      success: true,
      code: "PENGATURAN_TAGIHAN_OTOMATIS_DETAIL",
      pesan: "detail pengaturan tagihan otomatis",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.simpan_tagihan_otomatis = async (req, res, next) => {
  try {
    await SubscriptionService.assertFeature(req.user.id, "tagihan_otomatis")

    const data = await tagihanOtomatisService.simpanPengaturanTagihanOtomatis(
      req.user.id,
      req.params.kontrak_id,
      req.body
    )

    res.status(200).json({
      success: true,
      code: "PENGATURAN_TAGIHAN_OTOMATIS_SAVED",
      pesan: "pengaturan tagihan otomatis berhasil disimpan",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.ubah_status_tagihan_otomatis = async (req, res, next) => {
  try {
    await SubscriptionService.assertFeature(req.user.id, "tagihan_otomatis")

    const data = await tagihanOtomatisService.ubahStatusPengaturanTagihanOtomatis(
      req.user.id,
      req.params.kontrak_id,
      req.body.status
    )

    res.status(200).json({
      success: true,
      code: "PENGATURAN_TAGIHAN_OTOMATIS_STATUS_UPDATED",
      pesan: "status pengaturan tagihan otomatis berhasil diubah",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.ambil_perpanjangan_otomatis = async (req, res, next) => {
  try {
    await SubscriptionService.assertFeature(req.user.id, "perpanjangan_otomatis")

    const data =
      await perpanjanganOtomatisService.ambilPengaturanPerpanjanganKontrakOtomatis(
        req.user.id,
        req.params.kontrak_id
      )

    res.status(200).json({
      success: true,
      code: "PENGATURAN_PERPANJANGAN_OTOMATIS_DETAIL",
      pesan: "detail pengaturan perpanjangan kontrak otomatis",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.simpan_perpanjangan_otomatis = async (req, res, next) => {
  try {
    await SubscriptionService.assertFeature(req.user.id, "perpanjangan_otomatis")

    const data =
      await perpanjanganOtomatisService.simpanPengaturanPerpanjanganKontrakOtomatis(
        req.user.id,
        req.params.kontrak_id,
        req.body
      )

    res.status(200).json({
      success: true,
      code: "PENGATURAN_PERPANJANGAN_OTOMATIS_SAVED",
      pesan: "pengaturan perpanjangan kontrak otomatis berhasil disimpan",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.ubah_status_perpanjangan_otomatis = async (req, res, next) => {
  try {
    await SubscriptionService.assertFeature(req.user.id, "perpanjangan_otomatis")

    const data =
      await perpanjanganOtomatisService.ubahStatusPengaturanPerpanjanganKontrakOtomatis(
        req.user.id,
        req.params.kontrak_id,
        req.body.status
      )

    res.status(200).json({
      success: true,
      code: "PENGATURAN_PERPANJANGAN_OTOMATIS_STATUS_UPDATED",
      pesan: "status pengaturan perpanjangan kontrak otomatis berhasil diubah",
      data,
    })
  } catch (error) {
    next(error)
  }
}
