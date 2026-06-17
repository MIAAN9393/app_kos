require("../model/index")

const Bcrypt = require("bcrypt")
const { Op } = require("sequelize")
const User = require("../model/user")
const Kos = require("../model/kos")
const Kamar = require("../model/kamar")
const Penyewa = require("../model/penyewa")
const Kontrak = require("../model/kontrak")
const Tagihan = require("../model/tagihan")
const cloudinary = require("../config/cloudinary")
const { throwError } = require("../utils/error")
const {
  validasiUpdateProfile,
  validasiGantiPassword,
} = require("../validator/profile_validator")

async function ambilUserLogin(userId) {
  const user = await User.findOne({ where: { id: userId } })
  if (!user) {
    throwError("user tidak ditemukan", 404, "USER_NOT_FOUND")
  }
  return user
}

function pastikanCloudinarySiap() {
  if (
    !process.env.CLOUDINARY_CLOUD_NAME ||
    !process.env.CLOUDINARY_API_KEY ||
    !process.env.CLOUDINARY_API_SECRET
  ) {
    throwError("konfigurasi Cloudinary belum lengkap", 500, "CLOUDINARY_CONFIG_MISSING")
  }
}

function uploadFotoProfile(file) {
  pastikanCloudinarySiap()

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: "app-kos/profile",
        resource_type: "image",
      },
      (error, result) => {
        if (error) return reject(error)
        resolve(result)
      },
    )

    stream.end(file.buffer)
  })
}

function getCloudinaryPublicIdFromUrl(url) {
  const text = `${url ?? ""}`.trim()
  if (!text) return null

  let parsed
  try {
    parsed = new URL(text)
  } catch (_) {
    return null
  }

  const cloudName = process.env.CLOUDINARY_CLOUD_NAME
  if (
    parsed.hostname !== "res.cloudinary.com" ||
    !cloudName ||
    !parsed.pathname.startsWith(`/${cloudName}/image/upload/`)
  ) {
    return null
  }

  const uploadPrefix = `/${cloudName}/image/upload/`
  const afterUpload = parsed.pathname.slice(uploadPrefix.length)
  const parts = afterUpload.split("/").filter(Boolean)

  if (parts[0] && /^v\d+$/.test(parts[0])) {
    parts.shift()
  }

  if (!parts.length) return null

  const publicIdWithExtension = parts.join("/")
  return publicIdWithExtension.replace(/\.[^/.]+$/, "")
}

async function deleteCloudinaryImageByUrl(url) {
  const publicId = getCloudinaryPublicIdFromUrl(url)
  if (!publicId) return

  try {
    await cloudinary.uploader.destroy(publicId)
  } catch (error) {
    console.warn("Gagal menghapus foto profile lama dari Cloudinary:", error.message || error)
  }
}

function profileResponse(user, summary) {
  return {
    user: {
      id: user.id,
      nama: user.nama,
      email: user.email,
      email_verified: user.email_verified,
      no_telpon: user.no_telpon,
      phone_verified: user.phone_verified,
      foto_url: user.foto_url,
      role: user.role,
      status: user.status,
      created_at: user.created_at,
      bisa_ganti_password: !!user.password,
    },
    summary,
  }
}

async function hitungSummary(pemilikId) {
  const kosRows = await Kos.findAll({
    where: { pemilik_id: pemilikId, status: "aktif" },
    attributes: ["id"],
    raw: true,
  })
  const kosIds = kosRows.map((row) => row.id)

  const kamarRows = kosIds.length
    ? await Kamar.findAll({
        where: { kos_id: { [Op.in]: kosIds }, status: "aktif" },
        attributes: ["id"],
        raw: true,
      })
    : []
  const kamarIds = kamarRows.map((row) => row.id)

  const kontrakRows = kamarIds.length
    ? await Kontrak.findAll({
        where: { kamar_id: { [Op.in]: kamarIds } },
        attributes: ["id"],
        raw: true,
      })
    : []
  const kontrakIds = kontrakRows.map((row) => row.id)

  const tagihanBelumLunas = kontrakIds.length
    ? await Tagihan.count({
        where: {
          kontrak_id: { [Op.in]: kontrakIds },
          lifecycle: "issued",
          status_pembayaran: { [Op.in]: ["belum_bayar", "sebagian", "telat"] },
        },
      })
    : 0

  return {
    total_kos: kosRows.length,
    total_kamar: kamarRows.length,
    total_penyewa: await Penyewa.count({
      where: { pemilik_id: pemilikId, status: "aktif" },
    }),
    tagihan_belum_lunas: tagihanBelumLunas,
  }
}

exports.ambilProfile = async (userLogin) => {
  const user = await ambilUserLogin(userLogin.id)
  const summary = await hitungSummary(user.id)
  return profileResponse(user, summary)
}

exports.updateProfile = async (userLogin, body, file) => {
  const { nama } = validasiUpdateProfile(body)
  const user = await ambilUserLogin(userLogin.id)
  const oldFotoUrl = user.foto_url

  const payload = { nama }
  let newFotoUrl = null

  if (file) {
    const hasilUpload = await uploadFotoProfile(file)
    newFotoUrl = hasilUpload.secure_url
    payload.foto_url = newFotoUrl
  }

  await user.update(payload)

  if (file && oldFotoUrl && oldFotoUrl !== newFotoUrl) {
    await deleteCloudinaryImageByUrl(oldFotoUrl)
  }

  const summary = await hitungSummary(user.id)
  return profileResponse(user, summary)
}

exports.getCloudinaryPublicIdFromUrl = getCloudinaryPublicIdFromUrl
exports.deleteCloudinaryImageByUrl = deleteCloudinaryImageByUrl

exports.gantiPassword = async (userLogin, body) => {
  const { password_lama, password_baru } = validasiGantiPassword(body)
  const user = await ambilUserLogin(userLogin.id)

  if (!user.password) {
    throwError("akun ini login dengan Google dan tidak punya password", 403, "GOOGLE_ACCOUNT")
  }

  const cocok = await Bcrypt.compare(password_lama, user.password)
  if (!cocok) {
    throwError("password lama salah", 401, "INVALID_PASSWORD")
  }

  const hashPassword = await Bcrypt.hash(password_baru, 10)
  await user.update({ password: hashPassword })

  return { id: user.id, email: user.email }
}
