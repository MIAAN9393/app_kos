const { Op } = require("sequelize")
const sequelize = require("../config/database")
const Kamar = require("../model/kamar")
const Kos = require("../model/kos")
const Kontrak = require("../model/kontrak")
const Pembayaran = require("../model/pembayaran")
const Penyewa = require("../model/penyewa")
const Tagihan = require("../model/tagihan")
const { resetStatusPenyewa } = require("../utils/penyewa_helper")
const { ambil_tanggal_timezone } = require("../utils/waktu")
const WhatsAppService = require("./whatsapp_service")
const FcmEventService = require("./fcm_event_service")

const unik = (items) => [...new Set(items.filter((item) => item != null))]

const tambahHari = (tanggal, jumlah) => {
  const d = new Date(`${tanggal}T00:00:00+07:00`)
  d.setDate(d.getDate() + jumlah)
  return ambil_tanggal_timezone(d)
}

const safeFcmSummary = async (label, fn, fallback) => {
  try {
    return await fn()
  } catch (error) {
    console.error(`[fcm:${label}] gagal`, error?.message || error)
    return fallback
  }
}

const kondisiKontrakAktifHariIni = (hariIni) => ({
  status: "aktif",
  tanggal_mulai: { [Op.lte]: hariIni },
  [Op.or]: [
    { tanggal_selesai: null },
    { tanggal_selesai: { [Op.gte]: hariIni } },
  ],
})

const hitungTotalDibayarMap = async (tagihanIds, transaction) => {
  if (tagihanIds.length === 0) return {}

  const rows = await Pembayaran.findAll({
    attributes: [
      "tagihan_id",
      [
        sequelize.fn(
          "SUM",
          sequelize.literal(
            "CASE WHEN status = 'valid' THEN jumlah_bayar WHEN status = 'refund' THEN -jumlah_bayar ELSE 0 END"
          )
        ),
        "total_dibayar",
      ],
    ],
    where: {
      tagihan_id: { [Op.in]: tagihanIds },
    },
    group: ["tagihan_id"],
    raw: true,
    transaction,
  })

  return Object.fromEntries(
    rows.map((row) => [Number(row.tagihan_id), Number(row.total_dibayar) || 0])
  )
}

const sinkronkanStatusKamar = async (kamarIds, hariIni, transaction) => {
  const ids = unik(kamarIds)
  if (ids.length === 0) {
    return {
      total_kamar: 0,
      kosong: 0,
      sebagian: 0,
      penuh: 0,
    }
  }

  const kamars = await Kamar.findAll({
    attributes: ["id", "kapasitas"],
    where: {
      id: { [Op.in]: ids },
      status: "aktif",
    },
    transaction,
    lock: transaction.LOCK.UPDATE,
  })

  const kamarAktifIds = kamars.map((kamar) => kamar.id)
  if (kamarAktifIds.length === 0) {
    return {
      total_kamar: 0,
      kosong: 0,
      sebagian: 0,
      penuh: 0,
    }
  }

  const penghuniRows = await Kontrak.findAll({
    attributes: [
      "kamar_id",
      [sequelize.fn("COUNT", sequelize.col("id")), "jumlah_penghuni"],
    ],
    where: {
      kamar_id: { [Op.in]: kamarAktifIds },
      ...kondisiKontrakAktifHariIni(hariIni),
    },
    group: ["kamar_id"],
    raw: true,
    transaction,
  })

  const penghuniMap = Object.fromEntries(
    penghuniRows.map((row) => [
      Number(row.kamar_id),
      Number(row.jumlah_penghuni) || 0,
    ])
  )

  const kosongIds = []
  const sebagianIds = []
  const penuhIds = []

  for (const kamar of kamars) {
    const jumlahPenghuni = penghuniMap[kamar.id] || 0
    const kapasitas = Number(kamar.kapasitas) || 0

    if (jumlahPenghuni <= 0) {
      kosongIds.push(kamar.id)
    } else if (kapasitas > 0 && jumlahPenghuni >= kapasitas) {
      penuhIds.push(kamar.id)
    } else {
      sebagianIds.push(kamar.id)
    }
  }

  const updateKamar = async (statusKondisi, targetIds) => {
    if (targetIds.length === 0) return 0
    const [count] = await Kamar.update(
      { status_kondisi: statusKondisi },
      {
        where: {
          id: { [Op.in]: targetIds },
          status: "aktif",
        },
        transaction,
      }
    )
    return count
  }

  await updateKamar("kosong", kosongIds)
  await updateKamar("sebagian", sebagianIds)
  await updateKamar("penuh", penuhIds)

  return {
    total_kamar: kamarAktifIds.length,
    kosong: kosongIds.length,
    sebagian: sebagianIds.length,
    penuh: penuhIds.length,
  }
}

exports.syncKontrakDanKamar = async (tanggal = new Date()) => {
  const hariIni = ambil_tanggal_timezone(tanggal)
  const targetReminder = tambahHari(hariIni, 7)
  const t = await sequelize.transaction()

  try {
    const pendingAktifRows = await Kontrak.findAll({
      attributes: ["id", "kamar_id", "penyewa_id"],
      where: {
        status: "pending",
        tanggal_mulai: { [Op.lte]: hariIni },
        [Op.or]: [
          { tanggal_selesai: null },
          { tanggal_selesai: { [Op.gte]: hariIni } },
        ],
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    const selesaiRows = await Kontrak.findAll({
      attributes: ["id", "kamar_id", "penyewa_id"],
      where: {
        status: "aktif",
        tanggal_selesai: {
          [Op.ne]: null,
          [Op.lt]: hariIni,
        },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    const pendingAktifIds = pendingAktifRows.map((row) => row.id)
    const selesaiIds = selesaiRows.map((row) => row.id)
    const kamarTerdampakIds = unik([
      ...pendingAktifRows.map((row) => row.kamar_id),
      ...selesaiRows.map((row) => row.kamar_id),
    ])
    const penyewaTerdampakIds = unik([
      ...pendingAktifRows.map((row) => row.penyewa_id),
      ...selesaiRows.map((row) => row.penyewa_id),
    ])

    let kontrakDiaktifkan = 0
    let kontrakDiselesaikan = 0

    if (pendingAktifIds.length > 0) {
      const [count] = await Kontrak.update(
        { status: "aktif" },
        {
          where: { id: { [Op.in]: pendingAktifIds } },
          transaction: t,
        }
      )
      kontrakDiaktifkan = count
    }

    if (selesaiIds.length > 0) {
      const [count] = await Kontrak.update(
        { status: "selesai" },
        {
          where: { id: { [Op.in]: selesaiIds } },
          transaction: t,
        }
      )
      kontrakDiselesaikan = count
    }

    for (const penyewaId of penyewaTerdampakIds) {
      await resetStatusPenyewa(penyewaId, t)
    }

    const kamar = await sinkronkanStatusKamar(kamarTerdampakIds, hariIni, t)

    await t.commit()

    const reminderRows = await Kontrak.findAll({
      where: {
        status: "aktif",
        tanggal_selesai: targetReminder,
      },
      include: [
        {
          model: Penyewa,
          required: true,
        },
        {
          model: Kamar,
          required: true,
          include: {
            model: Kos,
            required: true,
          },
        },
      ],
    })

    const reminderKontrak = {
      sent: 0,
      failed: 0,
      skipped: 0,
    }

    for (const kontrak of reminderRows) {
      const result = await WhatsAppService.kirimReminderKontrakSebelumSelesai({
        user_id: kontrak.Kamar.Kos.pemilik_id,
        kontrak,
        penyewa: kontrak.Penyewa,
        kamar: kontrak.Kamar,
        kos: kontrak.Kamar.Kos,
        today: hariIni,
      })

      if (result.status === "sent") {
        reminderKontrak.sent += 1
      } else if (result.status === "failed") {
        reminderKontrak.failed += 1
        console.error("[cron:kontrak] gagal kirim reminder WhatsApp", {
          kontrak_id: kontrak.id,
          error: result.message,
        })
      } else {
        reminderKontrak.skipped += 1
      }
    }

    const fcmKontrak = await safeFcmSummary(
      "kontrak",
      () =>
        FcmEventService.notifyKontrakDailySummary(
          hariIni,
          targetReminder,
          selesaiIds
        ),
      { expiring_h7: 0, expired: 0 }
    )

    return {
      tanggal: hariIni,
      kontrak_diaktifkan: kontrakDiaktifkan,
      kontrak_diselesaikan: kontrakDiselesaikan,
      penyewa_disinkronkan: penyewaTerdampakIds.length,
      reminder_kontrak_h7: reminderKontrak,
      fcm_kontrak: fcmKontrak,
      kamar,
    }
  } catch (error) {
    await t.rollback()
    throw error
  }
}

exports.syncTagihan = async (tanggal = new Date()) => {
  const hariIni = ambil_tanggal_timezone(tanggal)
  const t = await sequelize.transaction()
  let tagihanDiterbitkan = []

  try {
    tagihanDiterbitkan = await Tagihan.findAll({
      attributes: ["id"],
      where: {
        lifecycle: "draft",
        periode_awal: { [Op.lte]: hariIni },
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
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    const [issuedCount] = await Tagihan.update(
      { lifecycle: "issued" },
      {
        where: {
          lifecycle: "draft",
          periode_awal: { [Op.lte]: hariIni },
        },
        transaction: t,
      }
    )

    const tagihans = await Tagihan.findAll({
      attributes: ["id", "total_tagihan", "jatuh_tempo", "status_pembayaran"],
      where: {
        lifecycle: { [Op.ne]: "cancelled" },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    const tagihanIds = tagihans.map((tagihan) => tagihan.id)
    const totalDibayarMap = await hitungTotalDibayarMap(tagihanIds, t)

    const statusIds = {
      lunas: [],
      telat: [],
      sebagian: [],
      belum_bayar: [],
    }

    for (const tagihan of tagihans) {
      const totalTagihan = Number(tagihan.total_tagihan) || 0
      const totalDibayar = totalDibayarMap[tagihan.id] || 0
      const jatuhTempo = tagihan.jatuh_tempo
        ? ambil_tanggal_timezone(tagihan.jatuh_tempo)
        : null

      if (totalDibayar >= totalTagihan) {
        statusIds.lunas.push(tagihan.id)
      } else if (jatuhTempo && jatuhTempo < hariIni) {
        statusIds.telat.push(tagihan.id)
      } else if (totalDibayar > 0 && totalDibayar < totalTagihan) {
        statusIds.sebagian.push(tagihan.id)
      } else {
        statusIds.belum_bayar.push(tagihan.id)
      }
    }

    const updateStatus = async (statusPembayaran, ids) => {
      if (ids.length === 0) return 0
      const [count] = await Tagihan.update(
        { status_pembayaran: statusPembayaran },
        {
          where: {
            id: { [Op.in]: ids },
            lifecycle: { [Op.ne]: "cancelled" },
          },
          transaction: t,
        }
      )
      return count
    }

    const lunas = await updateStatus("lunas", statusIds.lunas)
    const telat = await updateStatus("telat", statusIds.telat)
    const sebagian = await updateStatus("sebagian", statusIds.sebagian)
    const belumBayar = await updateStatus("belum_bayar", statusIds.belum_bayar)

    await t.commit()

    const whatsappInvoice = {
      sent: 0,
      failed: 0,
      skipped: 0,
    }

    for (const row of tagihanDiterbitkan) {
      const pemilikId = row.Kontrak?.Kamar?.Kos?.pemilik_id
      if (!pemilikId) {
        whatsappInvoice.skipped += 1
        continue
      }

      try {
        const hasilWa =
          await WhatsAppService.kirimInvoiceTagihanOtomatisDariCron(
            pemilikId,
            row.id
          )
        const status = hasilWa.whatsapp_invoice_status
        if (status === "sent") {
          whatsappInvoice.sent += 1
        } else if (status === "failed") {
          whatsappInvoice.failed += 1
        } else {
          whatsappInvoice.skipped += 1
        }
      } catch (error) {
        whatsappInvoice.failed += 1
        console.error("[cron:tagihan] gagal kirim invoice WhatsApp", {
          tagihan_id: row.id,
          error: error?.message || error,
        })
      }
    }

    const fcmTagihan = await safeFcmSummary(
      "tagihan",
      () => FcmEventService.notifyTagihanDailySummary(hariIni),
      { due_today: 0, overdue: 0 }
    )

    return {
      tanggal: hariIni,
      lifecycle_issued: issuedCount,
      whatsapp_invoice: whatsappInvoice,
      fcm_tagihan: fcmTagihan,
      status_pembayaran: {
        lunas,
        telat,
        sebagian,
        belum_bayar: belumBayar,
      },
    }
  } catch (error) {
    await t.rollback()
    throw error
  }
}
