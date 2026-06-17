const { Op } = require("sequelize")
const sequelize = require("../config/database")
const Kontrak = require("../model/kontrak")
const PengaturanTagihanOtomatis = require("../model/pengaturan_tagihan_otomatis")
const PengaturanPerpanjanganKontrakOtomatis = require("../model/pengaturan_perpanjangan_kontrak_otomatis")
const { buat_kode_kontrak } = require("../utils/kontrak_helper")
const Kamar = require("../model/kamar")
const Kos = require("../model/kos")
const FcmEventService = require("./fcm_event_service")
const { throwError } = require("../utils/error")
const {
  ambil_tanggal_timezone,
  tambah_hari,
  kurang_hari,
  hitung_akhir_periode,
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
    throwError(`${nama} tidak valid`, 400, "PENGATURAN_PERPANJANGAN_INVALID")
  }
  return angka
}

const normalisasiSiklus = (value) => {
  const siklus = String(value || "bulanan").toLowerCase()
  const valid = ["tahunan", "bulanan", "mingguan", "harian"]
  if (!valid.includes(siklus)) {
    throwError("jenis perpanjangan tidak valid", 400, "JENIS_PERPANJANGAN_INVALID")
  }
  return siklus
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

exports.ambilPengaturanPerpanjanganKontrakOtomatis = async (
  pemilik_id,
  kontrak_id
) => {
  const kontrak = await ambilKontrakMilikPemilik(pemilik_id, kontrak_id)
  const pengaturan = await PengaturanPerpanjanganKontrakOtomatis.findOne({
    where: { kontrak_id: kontrak.id },
  })

  return bentukResponsePengaturan(pengaturan, kontrak)
}

exports.simpanPengaturanPerpanjanganKontrakOtomatis = async (
  pemilik_id,
  kontrak_id,
  body
) => {
  const jenis_perpanjangan = normalisasiSiklus(body.jenis_perpanjangan)
  const jumlah_periode_perpanjangan = normalisasiInt(
    body.jumlah_periode_perpanjangan,
    "jumlah periode perpanjangan",
    { min: 1 }
  )
  const hari_sebelum_berakhir = normalisasiInt(
    body.hari_sebelum_berakhir,
    "hari sebelum berakhir"
  )
  const harga_perpanjangan =
    body.harga_perpanjangan == null || body.harga_perpanjangan === ""
      ? null
      : normalisasiInt(body.harga_perpanjangan, "harga perpanjangan", { min: 1 })
  const status = body.status === "nonaktif" ? "nonaktif" : "aktif"

  const t = await sequelize.transaction()

  try {
    const kontrak = await ambilKontrakMilikPemilik(pemilik_id, kontrak_id, t)
    if (!kontrak.tanggal_selesai) {
      throwError(
        "kontrak harus punya tanggal selesai untuk perpanjangan otomatis",
        400,
        "KONTRAK_TANGGAL_SELESAI_REQUIRED"
      )
    }

    const existing = await PengaturanPerpanjanganKontrakOtomatis.findOne({
      where: { kontrak_id: kontrak.id },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    const dataDasar = {
      kontrak_id: kontrak.id,
      jenis_perpanjangan,
      jumlah_periode_perpanjangan,
      hari_sebelum_berakhir,
      harga_perpanjangan,
      tanggal_proses_berikutnya: kurang_hari(
        kontrak.tanggal_selesai,
        hari_sebelum_berakhir
      ),
      status,
    }

    let pengaturan
    if (existing) {
      await existing.update(dataDasar, { transaction: t })
      pengaturan = existing
    } else {
      pengaturan = await PengaturanPerpanjanganKontrakOtomatis.create(
        {
          ...dataDasar,
          kontrak_terakhir_id: null,
        },
        { transaction: t }
      )
    }

    await t.commit()
    return bentukResponsePengaturan(pengaturan, kontrak)
  } catch (error) {
    await t.rollback()
    throw error
  }
}

exports.ubahStatusPengaturanPerpanjanganKontrakOtomatis = async (
  pemilik_id,
  kontrak_id,
  status
) => {
  const statusBaru = status === "aktif" ? "aktif" : "nonaktif"
  const t = await sequelize.transaction()

  try {
    const kontrak = await ambilKontrakMilikPemilik(pemilik_id, kontrak_id, t)
    const pengaturan = await PengaturanPerpanjanganKontrakOtomatis.findOne({
      where: { kontrak_id: kontrak.id },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!pengaturan) {
      throwError(
        "pengaturan perpanjangan kontrak otomatis belum dibuat",
        404,
        "PENGATURAN_NOT_FOUND"
      )
    }

    await pengaturan.update({ status: statusBaru }, { transaction: t })
    await t.commit()
    return bentukResponsePengaturan(pengaturan, kontrak)
  } catch (error) {
    await t.rollback()
    throw error
  }
}

const tentukanStatusKontrak = (tanggal_mulai, tanggal_selesai, hari_ini) => {
  if (hari_ini < tanggal_mulai) return "pending"
  if (hari_ini >= tanggal_mulai && hari_ini <= tanggal_selesai) return "aktif"
  return "pending"
}

const prosesSatuPengaturan = async (pengaturan_id, hari_ini) => {
  const t = await sequelize.transaction()

  try {
    const pengaturan = await PengaturanPerpanjanganKontrakOtomatis.findOne({
      where: {
        id: pengaturan_id,
        status: "aktif",
        kontrak_terakhir_id: null,
        tanggal_proses_berikutnya: { [Op.lte]: hari_ini },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!pengaturan) {
      await t.commit()
      return { status: "skip", alasan: "pengaturan tidak aktif atau sudah diproses" }
    }

    const kontrak_lama = await Kontrak.findOne({
      where: { id: pengaturan.kontrak_id },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!kontrak_lama || kontrak_lama.status !== "aktif") {
      await t.commit()
      return { status: "skip", alasan: "kontrak lama tidak aktif" }
    }

    if (!kontrak_lama.tanggal_selesai) {
      await t.commit()
      return { status: "skip", alasan: "kontrak lama tanpa tanggal selesai" }
    }

    const tanggal_mulai_baru = tambah_hari(kontrak_lama.tanggal_selesai, 1)
    const tanggal_selesai_baru = hitung_akhir_periode(
      tanggal_mulai_baru,
      pengaturan.jenis_perpanjangan,
      pengaturan.jumlah_periode_perpanjangan
    )

    if (!tanggal_mulai_baru || !tanggal_selesai_baru) {
      await t.commit()
      return { status: "skip", alasan: "tanggal kontrak baru tidak valid" }
    }

    const overlap = await Kontrak.count({
      where: {
        kamar_id: kontrak_lama.kamar_id,
        status: { [Op.in]: ["aktif", "pending"] },
        tanggal_mulai: { [Op.lte]: tanggal_selesai_baru },
        [Op.or]: [
          { tanggal_selesai: null },
          { tanggal_selesai: { [Op.gte]: tanggal_mulai_baru } },
        ],
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (overlap > 0) {
      await t.commit()
      return { status: "skip", alasan: "ada overlap kontrak kamar" }
    }

    const kode_kontrak = await buat_kode_kontrak(t)
    const kontrak_baru = await Kontrak.create(
      {
        kode_kontrak,
        penyewa_id: kontrak_lama.penyewa_id,
        kamar_id: kontrak_lama.kamar_id,
        tanggal_mulai: tanggal_mulai_baru,
        tanggal_selesai: tanggal_selesai_baru,
        harga_sewa: pengaturan.harga_perpanjangan ?? kontrak_lama.harga_sewa,
        siklus: pengaturan.jenis_perpanjangan,
        status: tentukanStatusKontrak(
          tanggal_mulai_baru,
          tanggal_selesai_baru,
          hari_ini
        ),
      },
      { transaction: t }
    )

    await pengaturan.update(
      {
        kontrak_terakhir_id: kontrak_baru.id,
        status: "nonaktif",
      },
      { transaction: t }
    )

    await PengaturanPerpanjanganKontrakOtomatis.create(
      {
        kontrak_id: kontrak_baru.id,
        jenis_perpanjangan: pengaturan.jenis_perpanjangan,
        jumlah_periode_perpanjangan: pengaturan.jumlah_periode_perpanjangan,
        hari_sebelum_berakhir: pengaturan.hari_sebelum_berakhir,
        harga_perpanjangan: pengaturan.harga_perpanjangan,
        tanggal_proses_berikutnya: kurang_hari(
          tanggal_selesai_baru,
          pengaturan.hari_sebelum_berakhir
        ),
        kontrak_terakhir_id: null,
        status: "aktif",
      },
      { transaction: t }
    )

    const pengaturan_tagihan_lama = await PengaturanTagihanOtomatis.findOne({
      where: { kontrak_id: kontrak_lama.id },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (pengaturan_tagihan_lama) {
      const sudahAdaPengaturanTagihan = await PengaturanTagihanOtomatis.findOne({
        where: { kontrak_id: kontrak_baru.id },
        transaction: t,
        lock: t.LOCK.UPDATE,
      })

      if (!sudahAdaPengaturanTagihan) {
        await PengaturanTagihanOtomatis.create(
          {
            kontrak_id: kontrak_baru.id,
            hari_sebelum_periode_mulai:
              pengaturan_tagihan_lama.hari_sebelum_periode_mulai,
            jatuh_tempo_setelah_periode_mulai_hari:
              pengaturan_tagihan_lama.jatuh_tempo_setelah_periode_mulai_hari,
            tanggal_proses_berikutnya: kurang_hari(
              tanggal_mulai_baru,
              pengaturan_tagihan_lama.hari_sebelum_periode_mulai
            ),
            periode_awal_terakhir_dibuat: null,
            periode_akhir_terakhir_dibuat: null,
            tagihan_terakhir_id: null,
            status: pengaturan_tagihan_lama.status,
          },
          { transaction: t }
        )
      }
    }

    await t.commit()
    return { status: "berhasil", kontrak_id: kontrak_baru.id }
  } catch (error) {
    await t.rollback()
    throw error
  }
}

exports.generatePerpanjanganKontrakOtomatis = async () => {
  const hari_ini = ambil_tanggal_timezone()

  const list_pengaturan = await PengaturanPerpanjanganKontrakOtomatis.findAll({
    attributes: ["id"],
    where: {
      status: "aktif",
      kontrak_terakhir_id: null,
      tanggal_proses_berikutnya: { [Op.lte]: hari_ini },
    },
    include: {
      model: Kontrak,
      as: "kontrakAwal",
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
    const pemilikId = row.kontrakAwal?.Kamar?.Kos?.pemilik_id
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
      console.error("[perpanjangan-otomatis] gagal memproses pengaturan", row.id, error.message)
    }
  }

  try {
    await FcmEventService.notifyPerpanjanganAutoSummary(hasil)
  } catch (error) {
    console.error("[fcm:perpanjangan-otomatis] gagal", error?.message || error)
  }
  return hasil
}
