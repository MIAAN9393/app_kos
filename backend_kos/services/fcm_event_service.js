const { Op } = require("sequelize")
const Kontrak = require("../model/kontrak")
const Tagihan = require("../model/tagihan")
const Kamar = require("../model/kamar")
const Kos = require("../model/kos")
const FcmService = require("./fcm_service")
const FcmSettingService = require("./fcm_notification_setting_service")

const groupByPemilik = (rows, getPemilikId) => {
  const map = new Map()

  for (const row of rows) {
    const pemilikId = getPemilikId(row)
    if (!pemilikId) continue
    map.set(pemilikId, (map.get(pemilikId) || 0) + 1)
  }

  return map
}

const sendSummary = async (userId, payload) => {
  try {
    return await FcmService.sendToUser(userId, payload)
  } catch (error) {
    console.error("[fcm:event] gagal kirim ringkasan", error?.message || error)
    return { sent: 0, failed: 1, skipped: 0 }
  }
}

const filteredEntries = async (map, settingKey) => {
  const allowed = await FcmSettingService.filterAktif([...map.keys()], settingKey)
  return [...map.entries()].filter(([userId]) => allowed.has(userId))
}

exports.notifyTagihanDailySummary = async (tanggal) => {
  const tagihanJatuhTempo = await Tagihan.findAll({
    attributes: ["id"],
    where: {
      lifecycle: "issued",
      jatuh_tempo: tanggal,
      status_pembayaran: { [Op.ne]: "lunas" },
    },
    include: {
      model: Kontrak,
      required: true,
      attributes: ["id"],
      include: {
        model: Kamar,
        required: true,
        attributes: ["id"],
        include: {
          model: Kos,
          required: true,
          attributes: ["pemilik_id"],
        },
      },
    },
  })

  const tagihanTelat = await Tagihan.findAll({
    attributes: ["id"],
    where: {
      lifecycle: "issued",
      status_pembayaran: "telat",
    },
    include: {
      model: Kontrak,
      required: true,
      attributes: ["id"],
      include: {
        model: Kamar,
        required: true,
        attributes: ["id"],
        include: {
          model: Kos,
          required: true,
          attributes: ["pemilik_id"],
        },
      },
    },
  })

  const dueByOwner = groupByPemilik(
    tagihanJatuhTempo,
    (row) => row.Kontrak?.Kamar?.Kos?.pemilik_id
  )
  const overdueByOwner = groupByPemilik(
    tagihanTelat,
    (row) => row.Kontrak?.Kamar?.Kos?.pemilik_id
  )

  const result = {
    due_today: 0,
    overdue: 0,
  }

  for (const [userId, count] of await filteredEntries(
    dueByOwner,
    "notif_tagihan_jatuh_tempo"
  )) {
    await sendSummary(userId, {
      title: "Tagihan jatuh tempo hari ini",
      body: `${count} tagihan perlu ditagih hari ini.`,
      data: {
        type: "tagihan_due_today",
        tanggal,
        count,
      },
    })
    result.due_today += count
  }

  for (const [userId, count] of await filteredEntries(
    overdueByOwner,
    "notif_tagihan_telat"
  )) {
    await sendSummary(userId, {
      title: "Tagihan terlambat",
      body: `${count} tagihan masih melewati jatuh tempo.`,
      data: {
        type: "tagihan_overdue",
        tanggal,
        count,
      },
    })
    result.overdue += count
  }

  return result
}

exports.notifyKontrakDailySummary = async (
  tanggal,
  targetReminder,
  selesaiIds = []
) => {
  const kontrakAkanBerakhir = await Kontrak.findAll({
    attributes: ["id"],
    where: {
      status: "aktif",
      tanggal_selesai: targetReminder,
    },
    include: {
      model: Kamar,
      required: true,
      attributes: ["id"],
      include: {
        model: Kos,
        required: true,
        attributes: ["pemilik_id"],
      },
    },
  })

  const kontrakBerakhir = selesaiIds.length
    ? await Kontrak.findAll({
        attributes: ["id"],
        where: {
          id: { [Op.in]: selesaiIds },
          status: "selesai",
        },
        include: {
          model: Kamar,
          required: true,
          attributes: ["id"],
          include: {
            model: Kos,
            required: true,
            attributes: ["pemilik_id"],
          },
        },
      })
    : []

  const expiringByOwner = groupByPemilik(
    kontrakAkanBerakhir,
    (row) => row.Kamar?.Kos?.pemilik_id
  )
  const expiredByOwner = groupByPemilik(
    kontrakBerakhir,
    (row) => row.Kamar?.Kos?.pemilik_id
  )

  const result = {
    expiring_h7: 0,
    expired: 0,
  }

  for (const [userId, count] of await filteredEntries(
    expiringByOwner,
    "notif_kontrak_akan_berakhir"
  )) {
    await sendSummary(userId, {
      title: "Kontrak akan berakhir",
      body: `${count} kontrak akan berakhir dalam 7 hari.`,
      data: {
        type: "kontrak_expiring",
        tanggal,
        target_tanggal: targetReminder,
        count,
      },
    })
    result.expiring_h7 += count
  }

  for (const [userId, count] of await filteredEntries(
    expiredByOwner,
    "notif_kontrak_selesai"
  )) {
    await sendSummary(userId, {
      title: "Kontrak sudah berakhir",
      body: `${count} kontrak baru saja ditandai selesai.`,
      data: {
        type: "kontrak_expired",
        tanggal,
        count,
      },
    })
    result.expired += count
  }

  return result
}

exports.notifyTagihanAutoSummary = async (hasil) => {
  if (!hasil?.byUser) return

  for (const [userId, item] of hasil.byUser) {
    if (
      !(await FcmSettingService.aktif(userId, "notif_tagihan_otomatis"))
    ) {
      continue
    }

    const parts = []
    if (item.berhasil > 0) parts.push(`${item.berhasil} berhasil`)
    if (item.error > 0) parts.push(`${item.error} gagal`)
    if (parts.length === 0) continue

    await sendSummary(userId, {
      title: "Tagihan otomatis",
      body: `Proses tagihan otomatis: ${parts.join(", ")}.`,
      data: {
        type: item.error > 0 ? "tagihan_auto_failed" : "tagihan_auto_created",
        count_success: item.berhasil,
        count_failed: item.error,
      },
    })
  }
}

exports.notifyPerpanjanganAutoSummary = async (hasil) => {
  if (!hasil?.byUser) return

  for (const [userId, item] of hasil.byUser) {
    if (
      !(await FcmSettingService.aktif(userId, "notif_perpanjangan_otomatis"))
    ) {
      continue
    }

    const parts = []
    if (item.berhasil > 0) parts.push(`${item.berhasil} berhasil`)
    if (item.error > 0) parts.push(`${item.error} gagal`)
    if (parts.length === 0) continue

    await sendSummary(userId, {
      title: "Perpanjangan kontrak otomatis",
      body: `Proses perpanjangan kontrak: ${parts.join(", ")}.`,
      data: {
        type:
          item.error > 0 ? "kontrak_auto_failed" : "kontrak_auto_extended",
        count_success: item.berhasil,
        count_failed: item.error,
      },
    })
  }
}
