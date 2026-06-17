const FcmNotificationSetting = require("../model/fcm_notification_setting")

const settingKeys = [
  "notif_tagihan_jatuh_tempo",
  "notif_tagihan_telat",
  "notif_tagihan_otomatis",
  "notif_kontrak_akan_berakhir",
  "notif_kontrak_selesai",
  "notif_perpanjangan_otomatis",
]

const defaultValues = Object.fromEntries(settingKeys.map((key) => [key, true]))

const toResponse = (row) => {
  const plain = row?.get ? row.get({ plain: true }) : row || {}
  return {
    ...defaultValues,
    ...Object.fromEntries(
      settingKeys.map((key) => [key, plain[key] !== false])
    ),
  }
}

exports.ambilAtauBuat = async (user_id) => {
  const [row] = await FcmNotificationSetting.findOrCreate({
    where: { user_id },
    defaults: { user_id, ...defaultValues },
  })
  return row
}

exports.ambilSettings = async (user_id) => {
  const row = await exports.ambilAtauBuat(user_id)
  return toResponse(row)
}

exports.simpanSettings = async (user_id, body = {}) => {
  const row = await exports.ambilAtauBuat(user_id)
  const payload = {}

  for (const key of settingKeys) {
    if (Object.prototype.hasOwnProperty.call(body, key)) {
      payload[key] = body[key] === true
    }
  }

  if (Object.keys(payload).length > 0) {
    await row.update(payload)
  }

  return toResponse(row)
}

exports.aktif = async (user_id, key) => {
  if (!user_id || !settingKeys.includes(key)) return true
  const row = await exports.ambilAtauBuat(user_id)
  return row[key] !== false
}

exports.filterAktif = async (userIds, key) => {
  const result = new Set()
  const ids = [...new Set(userIds.filter(Boolean))]

  for (const userId of ids) {
    if (await exports.aktif(userId, key)) result.add(userId)
  }

  return result
}
