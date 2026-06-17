const { Op } = require("sequelize")
const sequelize = require("../config/database")
const Kontrak = require("../model/kontrak")
const Tagihan = require("../model/tagihan")
const TagihanItem = require("../model/tagihan_item")
const PengaturanTagihanOtomatis = require("../model/pengaturan_tagihan_otomatis")
const { buat_kode_tagihan } = require("../utils/tagihan_helper")
const Kamar = require("../model/kamar")
const Kos = require("../model/kos")
const FcmEventService = require("./fcm_event_service")
const { throwError } = require("../utils/error")
const {
  ambil_tanggal_timezone,
  tambah_hari,
  kurang_hari,
  hitung_akhir_periode,
  hitung_tanggal_mulai_berikutnya,
} = require("../utils/waktu")

const buatRingkasan = (total = 0) => ({
  total,
  berhasil: 0,
  skip: 0,
  error: 0,
  byUser: new Map(),
})

const tambahRingkasanUser = (hasil, userId, field) => {
  if (!userId) return
  const current = hasil.byUser.get(userId) || { berhasil: 0, error: 0 }
  current[field] += 1
  hasil.byUser.set(userId, current)
}

const normalisasiInt = (value, nama, { min = 0 } = {}) => {
  const angka = Number(value)
  if (!Number.isInteger(angka) || angka < min) {
    throwError(`${nama} tidak valid`, 400, "PENGATURAN_TAGIHAN_INVALID")
  }
  return angka
}

const ambilKontrakMilikPemilik = async (pemilik_id, kontrak_id, transaction) => {
  const id = Number(kontrak_id)
  if (!Number.isInteger(id) || id <= 0) {
    throwError("kontrak tidak valid", 400, "KONTRAK_ID_INVALID")
  }

  const kontrak = await Kontrak.findOne({
    where: { id },
    include: {
      model: Kamar,
      required: true,
      include: {
        model: Kos,
        required: true,
        where: { pemilik_id },
      },
    },
    transaction,
    lock: transaction?.LOCK?.UPDATE,
  })

  if (!kontrak) {
    throwError(
      "kontrak tidak ditemukan atau bukan milik anda",
      404,
      "KONTRAK_NOT_FOUND"
    )
  }

  return kontrak
}

const tanggalProsesTagihan = (kontrak, pengaturan) => {
  const periodeAwal = pengaturan?.periode_akhir_terakhir_dibuat
    ? hitung_tanggal_mulai_berikutnya(pengaturan.periode_akhir_terakhir_dibuat)
    : kontrak.tanggal_mulai

  return kurang_hari(periodeAwal, pengaturan.hari_sebelum_periode_mulai)
}

const bentukResponsePengaturan = (pengaturan, kontrak) => {
  if (!pengaturan) return null

  const plain = pengaturan.get ? pengaturan.get({ plain: true }) : pengaturan
  return {
    ...plain,
    kontrak: kontrak
      ? {
          id: kontrak.id,
          kode_kontrak: kontrak.kode_kontrak,
          tanggal_mulai: kontrak.tanggal_mulai,
          tanggal_selesai: kontrak.tanggal_selesai,
          harga_sewa: kontrak.harga_sewa,
          siklus: kontrak.siklus,
          status: kontrak.status,
        }
      : undefined,
  }
}

exports.ambilPengaturanTagihanOtomatis = async (pemilik_id, kontrak_id) => {
  const kontrak = await ambilKontrakMilikPemilik(pemilik_id, kontrak_id)
  const pengaturan = await PengaturanTagihanOtomatis.findOne({
    where: { kontrak_id: kontrak.id },
    include: {
      model: Tagihan,
      as: "tagihanTerakhir",
      required: false,
    },
  })

  return bentukResponsePengaturan(pengaturan, kontrak)
}

exports.simpanPengaturanTagihanOtomatis = async (pemilik_id, kontrak_id, body) => {
  const hari_sebelum_periode_mulai = normalisasiInt(
    body.hari_sebelum_periode_mulai,
    "hari sebelum periode mulai"
  )
  const jatuh_tempo_setelah_periode_mulai_hari = normalisasiInt(
    body.jatuh_tempo_setelah_periode_mulai_hari,
    "jatuh tempo setelah periode mulai"
  )
  const status = body.status === "nonaktif" ? "nonaktif" : "aktif"

  const t = await sequelize.transaction()

  try {
    const kontrak = await ambilKontrakMilikPemilik(pemilik_id, kontrak_id, t)

    const existing = await PengaturanTagihanOtomatis.findOne({
      where: { kontrak_id: kontrak.id },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    const dataDasar = {
      kontrak_id: kontrak.id,
      hari_sebelum_periode_mulai,
      jatuh_tempo_setelah_periode_mulai_hari,
      status,
    }

    let pengaturan
    if (existing) {
      await existing.update(dataDasar, { transaction: t })
      pengaturan = existing
    } else {
      pengaturan = await PengaturanTagihanOtomatis.create(
        {
          ...dataDasar,
          periode_awal_terakhir_dibuat: null,
          periode_akhir_terakhir_dibuat: null,
          tagihan_terakhir_id: null,
        },
        { transaction: t }
      )
    }

    await pengaturan.update(
      {
        tanggal_proses_berikutnya: tanggalProsesTagihan(kontrak, pengaturan),
      },
      { transaction: t }
    )

    await t.commit()
    return bentukResponsePengaturan(pengaturan, kontrak)
  } catch (error) {
    await t.rollback()
    throw error
  }
}

exports.ubahStatusPengaturanTagihanOtomatis = async (
  pemilik_id,
  kontrak_id,
  status
) => {
  const statusBaru = status === "aktif" ? "aktif" : "nonaktif"
  const t = await sequelize.transaction()

  try {
    const kontrak = await ambilKontrakMilikPemilik(pemilik_id, kontrak_id, t)
    const pengaturan = await PengaturanTagihanOtomatis.findOne({
      where: { kontrak_id: kontrak.id },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!pengaturan) {
      throwError("pengaturan tagihan otomatis belum dibuat", 404, "PENGATURAN_NOT_FOUND")
    }

    await pengaturan.update({ status: statusBaru }, { transaction: t })
    await t.commit()
    return bentukResponsePengaturan(pengaturan, kontrak)
  } catch (error) {
    await t.rollback()
    throw error
  }
}

const tentukanLifecycleTagihan = (periode_awal, hari_ini) => {
  if (hari_ini < periode_awal) return "draft"
  return "issued"
}

const prosesSatuPengaturan = async (pengaturan_id, hari_ini) => {
  const t = await sequelize.transaction()

  try {
    const pengaturan = await PengaturanTagihanOtomatis.findOne({
      where: {
        id: pengaturan_id,
        status: "aktif",
        tanggal_proses_berikutnya: { [Op.lte]: hari_ini },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!pengaturan) {
      await t.commit()
      return { status: "skip", alasan: "pengaturan tidak aktif atau belum jatuh tempo" }
    }

    const kontrak = await Kontrak.findOne({
      where: { id: pengaturan.kontrak_id },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!kontrak || kontrak.status !== "aktif") {
      await t.commit()
      return { status: "skip", alasan: "kontrak tidak aktif" }
    }

    const periode_awal = pengaturan.periode_akhir_terakhir_dibuat
      ? hitung_tanggal_mulai_berikutnya(pengaturan.periode_akhir_terakhir_dibuat)
      : kontrak.tanggal_mulai

    const periode_akhir = hitung_akhir_periode(periode_awal, kontrak.siklus)

    if (!periode_awal || !periode_akhir) {
      await t.commit()
      return { status: "skip", alasan: "tanggal periode tidak valid" }
    }

    if (kontrak.tanggal_selesai && periode_awal > kontrak.tanggal_selesai) {
      await pengaturan.update({ status: "nonaktif" }, { transaction: t })
      await t.commit()
      return { status: "skip", alasan: "periode sudah melewati kontrak" }
    }

    if (kontrak.tanggal_selesai && periode_akhir > kontrak.tanggal_selesai) {
      await pengaturan.update({ status: "nonaktif" }, { transaction: t })
      await t.commit()
      return { status: "skip", alasan: "periode akhir melewati kontrak" }
    }

    const tagihanDuplikat = await Tagihan.findOne({
      where: {
        kontrak_id: kontrak.id,
        periode_awal,
        periode_akhir,
        lifecycle: { [Op.ne]: "cancelled" },
      },
      include: {
        model: TagihanItem,
        required: true,
        where: {
          tipe: "sewa",
        },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    const periode_awal_berikutnya = hitung_tanggal_mulai_berikutnya(periode_akhir)
    const tanggal_proses_berikutnya = kurang_hari(
      periode_awal_berikutnya,
      pengaturan.hari_sebelum_periode_mulai
    )

    if (tagihanDuplikat) {
      await pengaturan.update(
        {
          periode_awal_terakhir_dibuat: periode_awal,
          periode_akhir_terakhir_dibuat: periode_akhir,
          tagihan_terakhir_id: tagihanDuplikat.id,
          tanggal_proses_berikutnya,
        },
        { transaction: t }
      )

      await t.commit()
      return { status: "skip", alasan: "tagihan sewa periode sudah ada" }
    }

    const kode_tagihan = await buat_kode_tagihan(t)
    const jatuh_tempo = tambah_hari(
      periode_awal,
      pengaturan.jatuh_tempo_setelah_periode_mulai_hari
    )

    const tagihan = await Tagihan.create(
      {
        kode_tagihan,
        kontrak_id: kontrak.id,
        periode_awal,
        periode_akhir,
        jatuh_tempo,
        total_tagihan: kontrak.harga_sewa,
        lifecycle: tentukanLifecycleTagihan(periode_awal, hari_ini),
        status_pembayaran: "belum_bayar",
        catatan: "Tagihan otomatis dari cron",
      },
      { transaction: t }
    )

    await TagihanItem.create(
      {
        tagihan_id: tagihan.id,
        tipe: "sewa",
        nama_item: "Sewa kamar",
        deskripsi: "Tagihan sewa otomatis",
        nominal: kontrak.harga_sewa,
        event_date: periode_awal,
      },
      { transaction: t }
    )

    await pengaturan.update(
      {
        periode_awal_terakhir_dibuat: periode_awal,
        periode_akhir_terakhir_dibuat: periode_akhir,
        tagihan_terakhir_id: tagihan.id,
        tanggal_proses_berikutnya,
      },
      { transaction: t }
    )

    await t.commit()
    return { status: "berhasil", tagihan_id: tagihan.id }
  } catch (error) {
    await t.rollback()
    throw error
  }
}

exports.generateTagihanOtomatis = async () => {
  const hari_ini = ambil_tanggal_timezone()

  const list_pengaturan = await PengaturanTagihanOtomatis.findAll({
    attributes: ["id"],
    where: {
      status: "aktif",
      tanggal_proses_berikutnya: { [Op.lte]: hari_ini },
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
    order: [["id", "ASC"]],
  })

  const hasil = buatRingkasan(list_pengaturan.length)

  for (const row of list_pengaturan) {
    const pemilikId = row.Kontrak?.Kamar?.Kos?.pemilik_id
    try {
      const proses = await prosesSatuPengaturan(row.id, hari_ini)
      if (proses.status === "berhasil") {
        hasil.berhasil += 1
        tambahRingkasanUser(hasil, pemilikId, "berhasil")
      } else {
        hasil.skip += 1
      }
    } catch (error) {
      hasil.error += 1
      tambahRingkasanUser(hasil, pemilikId, "error")
      console.error("[tagihan-otomatis] gagal memproses pengaturan", row.id, error.message)
    }
  }

  try {
    await FcmEventService.notifyTagihanAutoSummary(hasil)
  } catch (error) {
    console.error("[fcm:tagihan-otomatis] gagal", error?.message || error)
  }
  return hasil
}
