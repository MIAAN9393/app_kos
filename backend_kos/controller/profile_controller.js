const ProfileService = require("../services/profile_service")

exports.ambilProfile = async (req, res, next) => {
  try {
    const data = await ProfileService.ambilProfile(req.user)

    res.status(200).json({
      success: true,
      code: "PROFILE_SUCCESS",
      pesan: "profile berhasil diambil",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.updateProfile = async (req, res, next) => {
  try {
    const data = await ProfileService.updateProfile(req.user, req.body, req.file)

    res.status(200).json({
      success: true,
      code: "PROFILE_UPDATED",
      pesan: "profile berhasil diperbarui",
      data,
    })
  } catch (error) {
    next(error)
  }
}

exports.gantiPassword = async (req, res, next) => {
  try {
    const data = await ProfileService.gantiPassword(req.user, req.body)

    res.status(200).json({
      success: true,
      code: "PASSWORD_UPDATED",
      pesan: "password berhasil diperbarui",
      data,
    })
  } catch (error) {
    next(error)
  }
}
