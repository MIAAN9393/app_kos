const Penyewa = require("../model/penyewa")
const Kos = require("../model/kos")
const Kamar = require("../model/kamar")
const Kontrak = require("../model/kontrak")
const sequelize = require("../config/database")
const { Op } = require("sequelize")
const { throwError } = require("../utils/error")
const { validasi_kontrak } = require("../validator/kontrak_validator")
const { resetStatusKamar } = require("../utils/kamar_helper")
const { resetStatusPenyewa } = require("../utils/penyewa_helper")
const KontrakResponse = require("../response/kontrak_response")
const { buat_kode_kontrak } = require("../utils/kontrak_helper")
const { ambil_tanggal_doang } = require("../utils/waktu")
const WhatsAppService = require("./whatsapp_service")
const { buatPublicToken, pastikanPublicToken } = require("../utils/public_token")

exports.ambil_kontrak = async (pemilik_id, penyewa_id) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  if (!penyewa_id) {
    throwError("penyewa tidak ditemukan", 400, "PENYEWA_NOT_FOUND")
  }

  const penyewa = await Penyewa.findOne({
    where: {
      id: penyewa_id,
      pemilik_id: pemilik_id,
    },
  })

  if (!penyewa) {
    throwError(
      "penyewa tidak ada atau bukan milik anda",
      404,
      "PENYEWA_NOT_FOUND"
    )
  }

  const kontrak = await Kontrak.findOne({
    where: {
      penyewa_id: penyewa_id,
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
          where: {
            pemilik_id: pemilik_id,
          },
        },
      },
    ],
    order: [["id", "DESC"]],
  })

  if (!kontrak) {
    return null
  }

  await pastikanPublicToken(kontrak)

  return new KontrakResponse(kontrak)
}

exports.list_by_penyewa = async (pemilik_id, penyewa_id) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  if (!penyewa_id) {
    throwError("penyewa tidak ditemukan", 400, "PENYEWA_NOT_FOUND")
  }

  const penyewa = await Penyewa.findOne({
    where: {
      id: penyewa_id,
      pemilik_id: pemilik_id,
    },
  })

  if (!penyewa) {
    throwError(
      "penyewa tidak ada atau bukan milik anda",
      404,
      "PENYEWA_NOT_FOUND"
    )
  }

  const list_kontrak = await Kontrak.findAll({
    where: {
      penyewa_id: penyewa_id,
    },
    include: [
      {
        model: Penyewa,
        required: true,
        where: {
          pemilik_id: pemilik_id,
        },
      },
      {
        model: Kamar,
        required: true,
        include: {
          model: Kos,
          required: true,
          where: {
            pemilik_id: pemilik_id,
          },
        },
      },
    ],
    order: [
      ["tanggal_mulai", "DESC"],
      ["id", "DESC"],
    ],
  })

  await Promise.all(list_kontrak.map((kontrak) => pastikanPublicToken(kontrak)))

  return KontrakResponse.list(list_kontrak)
}

exports.ambil_semua_kontrak = async (pemilik_id) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  const list_kontrak = await Kontrak.findAll({
    include: [
      {
        model: Penyewa,
        required: true,
        where: { pemilik_id: pemilik_id },
      },
      {
        model: Kamar,
        required: true,
        attributes: ["id", "nomor", "kos_id"],
      },
    ],
    order: [["id", "DESC"]],
  })

  await Promise.all(list_kontrak.map((kontrak) => pastikanPublicToken(kontrak)))

  return KontrakResponse.list(list_kontrak)
}

exports.buat_kontrak = async (pemilik_id, body) => {
  const {
    penyewa_id,
    kamar_id,
    tanggal_mulai,
    tanggal_selesai,
    harga_sewa,
    siklus,
    status,
  } = await validasi_kontrak(body)

  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  const t = await sequelize.transaction()

  try {
    const penyewa = await Penyewa.findOne({
      where: {
        id: penyewa_id,
        pemilik_id: pemilik_id,
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!penyewa) {
      throwError("penyewa tidak ada", 400, "PENYEWA_NOT_FOUND")
    }

    const kamar = await Kamar.findOne({
      where: {
        id: kamar_id,
        status: { [Op.in]: ["aktif", "pending"] },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!kamar) {
      throwError("kamar tidak ada", 400, "KAMAR_NOT_FOUND")
    }

    const kos = await Kos.findOne({
      where: {
        id: kamar.kos_id,
        pemilik_id: pemilik_id,
        status: "aktif",
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!kos) {
      throwError("kos tidak ada", 400, "KOS_NOT_FOUND")
    }

    const konflik = await Kontrak.count({
      where: {
        penyewa_id: penyewa_id,
        status: { [Op.in]: ["aktif", "pending"] },
        tanggal_mulai: { [Op.lte]: tanggal_selesai },
        tanggal_selesai: { [Op.gte]: tanggal_mulai },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (konflik > 0) {
      throwError(
        "penyewa sudah dikontrak di tanggal tersebut",
        400,
        "KONTRAK_CONFLICT"
      )
    }

    const jumlah_kontrak = await Kontrak.count({
      where: {
        kamar_id: kamar_id,
        status: { [Op.in]: ["aktif", "pending"] },
        tanggal_mulai: { [Op.lte]: tanggal_selesai },
        tanggal_selesai: { [Op.gte]: tanggal_mulai },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (jumlah_kontrak >= kamar.kapasitas) {
      throwError("kamar sudah penuh", 400, "KAMAR_FULL")
    }

    const kode_kontrak = await buat_kode_kontrak(t)

    const kontrak = await Kontrak.create(
      {
        penyewa_id,
        kode_kontrak,
        public_token: buatPublicToken(),
        kamar_id,
        tanggal_mulai,
        tanggal_selesai,
        harga_sewa,
        siklus,
        status,
      },
      {
        transaction: t,
      }
    )

    await penyewa.update(
      {
        status: "aktif",
      },
      { transaction: t }
    )

    await resetStatusKamar(kamar_id, t)

    await t.commit()

    const whatsappKontrak =
      await WhatsAppService.kirimKontrakOtomatisSaatCreate(
        pemilik_id,
        kontrak.id
      )

    const plain = kontrak.get({ plain: true })
    return {
      ...plain,
      ...whatsappKontrak,
    }
  } catch (error) {
    await t.rollback()
    throw error
  }
}

exports.edit_kontrak = async (pemilik_id, kontrak_id, body) => {
  const {
    penyewa_id,
    kamar_id,
    tanggal_mulai,
    tanggal_selesai,
    harga_sewa,
    siklus,
    status,
  } = await validasi_kontrak(body)

  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  if (!kontrak_id) {
    throwError("kontrak tidak ditemukan", 401, "UNAUTHORIZED")
  }

  const t = await sequelize.transaction()

  try {
    const kontrak = await Kontrak.findOne({
      where: {
        id: kontrak_id,
      },
      include: {
        model: Kamar,
        required: true,
        include: {
          model: Kos,
          required: true,
          where: { pemilik_id: pemilik_id },
        },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!kontrak) {
      throwError(
        "kontrak tidak ada atau bukan milik anda",
        400,
        "KONTRAK_NOT_FOUND"
      )
    }

    if (kontrak.status != "pending") {
      throwError(
        "kontrak yang bisa di ubah hanya status pending atau belum aktif",
        400,
        "KONTRAK_EDIT_FORBIDEN"
      )
    }

    const kamar_id_lama = kontrak.kamar_id

    const penyewa = await Penyewa.findOne({
      where: {
        id: penyewa_id,
        pemilik_id: pemilik_id,
        status: "aktif",
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!penyewa) {
      throwError("penyewa tidak ada", 400, "PENYEWA_NOT_FOUND")
    }

    const kamar = await Kamar.findOne({
      where: {
        id: kamar_id,
        status: "aktif",
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!kamar) {
      throwError("kamar tidak ada", 400, "KAMAR_NOT_FOUND")
    }

    const kos = await Kos.findOne({
      where: {
        id: kamar.kos_id,
        pemilik_id: pemilik_id,
        status: "aktif",
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!kos) {
      throwError("kos tidak ada", 400, "KOS_NOT_FOUND")
    }

    const konflik = await Kontrak.findOne({
      where: {
        id: { [Op.ne]: kontrak_id },
        penyewa_id: penyewa_id,
        status: "aktif",
        tanggal_mulai: { [Op.lte]: tanggal_selesai },
        tanggal_selesai: { [Op.gte]: tanggal_mulai },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (konflik) {
      throwError(
        "penyewa sudah dikontrak di tanggal tersebut",
        400,
        "KONTRAK_CONFLICT"
      )
    }

    const jumlah_kontrak = await Kontrak.count({
      where: {
        id: { [Op.ne]: kontrak_id },
        kamar_id: kamar_id,
        status: { [Op.in]: ["aktif", "pending"] },
        tanggal_mulai: { [Op.lte]: tanggal_selesai },
        tanggal_selesai: { [Op.gte]: tanggal_mulai },
      },
      transaction: t,
    })

    if (jumlah_kontrak >= kamar.kapasitas) {
      throwError("kamar sudah penuh", 400, "KAMAR_FULL")
    }

    await kontrak.update(
      {
        penyewa_id,
        kamar_id,
        tanggal_mulai,
        tanggal_selesai,
        harga_sewa,
        siklus,
        status,
      },
      { transaction: t }
    )

    if (kamar_id != kamar_id_lama) {
      await Kamar.findOne({
        where: {
          id: kamar_id_lama,
        },
        transaction: t,
        lock: t.LOCK.UPDATE,
      })
      await resetStatusKamar(kamar_id_lama, t)
    }

    await resetStatusKamar(kamar_id, t)

    await t.commit()

    return kontrak
  } catch (error) {
    await t.rollback()
    throw error
  }
}

exports.hapus_kontrak = async (pemilik_id, kontrak_id) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  if (!kontrak_id) {
    throwError("kontrak tidak ditemukan", 400, "KONTRAK_NOT_FOUND")
  }

  const t = await sequelize.transaction()

  try {
    const kontrak = await Kontrak.findOne({
      where: { id: kontrak_id },
      include: {
        model: Kamar,
        include: {
          model: Kos,
          where: { pemilik_id },
        },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!kontrak) {
      throwError(
        "kontrak tidak ada atau bukan milik anda",
        404,
        "KONTRAK_NOT_FOUND"
      )
    }

    if (kontrak.status !== "pending") {
      throwError(
        "kontrak yang bisa dibatalkan hanya status pending",
        400,
        "KONTRAK_HAPUS_FORBIDEN"
      )
    }

    await kontrak.update(
      {
        status: "dibatalkan",
      },
      { transaction: t }
    )

    await resetStatusPenyewa(kontrak.penyewa_id, t)
    await resetStatusKamar(kontrak.kamar_id, t)

    await t.commit()

    return kontrak
  } catch (error) {
    await t.rollback()
    throw error
  }
}

exports.selsaikan_kontrak = async (pemilik_id, kontrak_id) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  if (!kontrak_id) {
    throwError("kontrak tidak ditemukan", 400, "KONTRAK_NOT_FOUND")
  }

  const t = await sequelize.transaction()

  try {
    const kontrak = await Kontrak.findOne({
      where: { id: kontrak_id },
      include: {
        model: Kamar,
        include: {
          model: Kos,
          where: { pemilik_id },
        },
      },
      transaction: t,
      lock: t.LOCK.UPDATE,
    })

    if (!kontrak) {
      throwError(
        "kontrak tidak ada atau bukan milik anda",
        404,
        "KONTRAK_NOT_FOUND"
      )
    }

    if (kontrak.status !== "aktif") {
      throwError(
        "hanya kontrak aktif yang bisa diselesaikan",
        400,
        "KONTRAK_TIDAK_AKTIF"
      )
    }

    const today = ambil_tanggal_doang(new Date())
    const tanggalMulai = ambil_tanggal_doang(kontrak.tanggal_mulai)

    if (tanggalMulai > today) {
      throwError(
        "kontrak belum berjalan tidak bisa diselesaikan",
        400,
        "KONTRAK_BELUM_BERJALAN"
      )
    }

    await kontrak.update(
      {
        tanggal_selesai: today,
        status: "selesai",
      },
      { transaction: t }
    )

    await resetStatusPenyewa(kontrak.penyewa_id, t)
    await resetStatusKamar(kontrak.kamar_id, t)

    await t.commit()

    return kontrak
  } catch (error) {
    await t.rollback()
    throw error
  }
}
