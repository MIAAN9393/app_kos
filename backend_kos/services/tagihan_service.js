const Tagihan = require("../model/tagihan");
const TagihanItem = require("../model/tagihan_item")
const Kontrak = require("../model/kontrak")
const Kamar = require("../model/kamar")
const Kos = require("../model/kos")
const { throwError } = require("../utils/error");
const { validasi_tagihan } = require("../validator/tagihan_validator");
const {
  buat_kode_tagihan,
  hitungTotalDibayar,
  pastikanBolehUbahTagihan,
} = require("../utils/tagihan_helper")
const { where, LOCK, Op } = require("sequelize");
const sequelize = require("../config/database");
const kamar = require("../model/kamar");
const Pembayaran = require("../model/pembayaran");
const TagihanResponse = require("../response/tagihan_response");
const { ambil_tanggal_doang } = require("../utils/waktu");
const WhatsAppService = require("./whatsapp_service")

function parseDateOnly(value) {
  if (!value) return null

  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) return null
    return new Date(value.getFullYear(), value.getMonth(), value.getDate())
  }

  const text = String(value).trim().split("T")[0]
  const parts = text.split("-")
  if (parts.length !== 3) return null

  const year = Number(parts[0])
  const month = Number(parts[1])
  const day = Number(parts[2])
  if (!year || !month || !day) return null

  const date = new Date(year, month - 1, day)
  return Number.isNaN(date.getTime()) ? null : date
}

function pastikanPeriodeDalamKontrak({
  periode_awal,
  tanggal_mulai,
  tanggal_selesai,
}) {
  const periodeAwal = parseDateOnly(periode_awal)
  const tanggalMulai = parseDateOnly(tanggal_mulai)
  const tanggalSelesai = parseDateOnly(tanggal_selesai)

  if (!periodeAwal || !tanggalMulai) {
    throwError(
      "tanggal periode awal tagihan atau tanggal mulai kontrak tidak valid",
      400,
      "TAGIHAN_TANGGAL_INVALID"
    )
  }

  if (
    periodeAwal < tanggalMulai ||
    (tanggalSelesai && periodeAwal > tanggalSelesai)
  ) {
    throwError(
      "periode awal tagihan harus berada di dalam periode kontrak",
      403,
      "TAGIHAN_PERIODE_DI_LUAR_KONTRAK"
    )
  }
}

exports.ambil_tagihan = async (pemilik_id,kontrak_id) => {

  //CEK PEMILIK

  const list_tagihan = await Tagihan.findAll({
    where: {
      kontrak_id: kontrak_id,
    },
    include: {
      model: Kontrak,
      required: true,
      include: {
        model: Kamar,
        required: true,
        include: {
          model: Kos,
          required: true,
          where: {
            pemilik_id: pemilik_id
          }
        }
      }
    }
  })

  if(!list_tagihan || list_tagihan.length == 0)
    return []

  const tagihan_ids = list_tagihan.map(i => i.id)

  const list_item = await TagihanItem.findAll({
    where: {
      tagihan_id: {
        [Op.in]: tagihan_ids
      }
    }
  })

  const pembayaran_rows = await Pembayaran.findAll({
    attributes: ["tagihan_id", "status", "jumlah_bayar"],
    where: {
      tagihan_id: {
        [Op.in]: tagihan_ids
      }
    },
    raw: true
  })

  const dibayar_map = {}

  for (const row of pembayaran_rows) {
    const tid = row.tagihan_id
    if (!dibayar_map[tid]) dibayar_map[tid] = []
    dibayar_map[tid].push(row)
  }

  for (const tid of Object.keys(dibayar_map)) {
    dibayar_map[tid] = hitungTotalDibayar(dibayar_map[tid])
  }

  return TagihanResponse.list(list_tagihan, list_item, dibayar_map)
}

exports.ambil_semua_tagihan = async (pemilik_id) => {

  // VALIDASI

  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  // AMBIL SEMUA TAGIHAN MILIK PEMILIK (Tagihan -> Kontrak -> Kamar -> Kos)

  const list_tagihan = await Tagihan.findAll({
    include: {
      model: Kontrak,
      required: true,
      include: {
        model: Kamar,
        required: true,
        include: {
          model: Kos,
          required: true,
          where: {
            pemilik_id: pemilik_id
          }
        }
      }
    },
    order: [["id", "DESC"]]
  })

  if (!list_tagihan || list_tagihan.length == 0)
    return []

  const tagihan_ids = list_tagihan.map(i => i.id)

  const list_item = await TagihanItem.findAll({
    where: {
      tagihan_id: {
        [Op.in]: tagihan_ids
      }
    }
  })

  const pembayaran_rows = await Pembayaran.findAll({
    attributes: ["tagihan_id", "status", "jumlah_bayar"],
    where: {
      tagihan_id: {
        [Op.in]: tagihan_ids
      }
    },
    raw: true
  })

  const dibayar_map = {}

  for (const row of pembayaran_rows) {
    const tid = row.tagihan_id
    if (!dibayar_map[tid]) dibayar_map[tid] = []
    dibayar_map[tid].push(row)
  }

  for (const tid of Object.keys(dibayar_map)) {
    dibayar_map[tid] = hitungTotalDibayar(dibayar_map[tid])
  }

  return TagihanResponse.list(list_tagihan, list_item, dibayar_map)
}

exports.buat_tagihan = async (pemilik_id,body) => {
  const {
    list_item,
    kontrak_id,
    periode_awal,
    periode_akhir,
    jatuh_tempo,
    total_tagihan,
    catatan,
    lifecycle
  } = await validasi_tagihan(body)

  //CEK PEMILIK

  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED");
  }
  
  const t = await sequelize.transaction()

  try {

    const kontrak = await Kontrak.findOne({
        where:{
          id:kontrak_id,
          status:"aktif",
        },
        include:{
          model:Kamar,
          include:{
            model:Kos,
            where:{
              pemilik_id:pemilik_id
            }
          }
        },
        transaction : t,
        lock : t.LOCK.UPDATE
      }
    )

    if (!kontrak) {
      throwError(
        "kontrak tidak ditemukan atau belum aktif",
        404,
        "KONTRAK_NOT_FOUND"
      )
    }

    pastikanPeriodeDalamKontrak({
      periode_awal,
      tanggal_mulai: kontrak.tanggal_mulai,
      tanggal_selesai: kontrak.tanggal_selesai,
    })
  
      const tagihanDuplikat = await Tagihan.findAll({
      where: {
        kontrak_id,
        lifecycle: {
          [Op.ne]: "cancelled",
        },
        periode_awal: {
          [Op.lte]: periode_akhir,
        },
        periode_akhir: {
          [Op.gte]: periode_awal,
        },
      },
      transaction: t,
      lock: t.LOCK.UPDATE
    })

    const list_id_tagihanDuplikat = tagihanDuplikat.map((i)=>i.id)

    const list_item_find = await TagihanItem.findAll({
      where:{
        tagihan_id:{
          [Op.in] : list_id_tagihanDuplikat
        }
      },
      transaction:t
    })

    const adaSewaLama = list_item_find.some((i) => i.tipe === "sewa")
    const adaSewaBaru = list_item.some((i) => i.tipe === "sewa")

    if (adaSewaLama && adaSewaBaru) {
      throwError(
        "Tagihan SEWA untuk periode ini sudah ada pada kontrak yang sama",
        400,
        "TAGIHAN_PERIODE_DUPLIKAT"
      )
    }

    const kode_tagihan = await buat_kode_tagihan(t)
    
    //AKSI
    const tagihan = await Tagihan.create({
        kode_tagihan,
        kontrak_id,
        periode_awal,
        periode_akhir,
        jatuh_tempo,
        total_tagihan,
        catatan,
        lifecycle
      },
      {
        transaction : t
      }
    )

    const list_item_created = await Promise.all(
      list_item.map( async (i)=>{
          return await TagihanItem.create({
              tagihan_id:tagihan.id,
              tipe:i.tipe,
              nama_item:i.nama_item,
              deskripsi:i.deskripsi??"",
              nominal:i.nominal
            },
            {
              transaction : t
            }
          )
        }
      )
    )

    await t.commit()

    const whatsappInvoice = await WhatsAppService
      .kirimInvoiceTagihanOtomatisSaatCreate(pemilik_id, tagihan.id)

    return {
      tagihan,
      list_item : list_item_created,
      ...whatsappInvoice
    }

  } catch (error) {

    await t.rollback()
    throw error
  }

}

exports.edit_tagihan = async (pemilik_id, tagihan_id, body) => {

  const {
    list_item,
    periode_awal,
    periode_akhir,
    jatuh_tempo,
    total_tagihan,
    catatan,
    lifecycle
  } = await validasi_tagihan(body)

  const t = await sequelize.transaction()

  try {

    // CEK KEPEMILIKAN TAGIHAN

    const tagihan = await Tagihan.findOne({
      where: {
        id: tagihan_id
      },
      include: {
        model: Kontrak,
        required: true,
        include: {
          model: Kamar,
          required: true,
          include: {
            model: Kos,
            required: true,
            where: {
              pemilik_id
            }
          }
        }
      },
      transaction: t,
      lock: t.LOCK.UPDATE
    })

    if (!tagihan) {
      throwError(
        "tagihan tidak ditemukan atau bukan milik anda",
        404,
        "TAGIHAN_NOT_FOUND"
      )
    }

    // CEK PEMBAYARAN

    const pembayaran = await Pembayaran.findAll({
      where: {
        tagihan_id: tagihan.id
      },
      transaction: t
    })

    const total_dibayar = hitungTotalDibayar(pembayaran)

    pastikanBolehUbahTagihan({
      total_tagihan: tagihan.total_tagihan,
      total_dibayar
    })

    pastikanPeriodeDalamKontrak({
      periode_awal,
      tanggal_mulai: tagihan.Kontrak.tanggal_mulai,
      tanggal_selesai: tagihan.Kontrak.tanggal_selesai,
    })
  
  

    // CEK OVERLAP PERIODE (KECUALI DIRINYA SENDIRI)

    const tagihanDuplikat = await Tagihan.findAll({
      where: {
        kontrak_id: tagihan.kontrak_id,

        id: {
          [Op.ne]: tagihan.id
        },

        lifecycle: {
          [Op.ne]: "cancelled"
        },

        periode_awal: {
          [Op.lte]: periode_akhir
        },

        periode_akhir: {
          [Op.gte]: periode_awal
        }
      },
      transaction: t,
      lock: t.LOCK.UPDATE
    })

    // CEK DUPLIKASI ITEM SEWA

    const list_id_tagihanDuplikat =
      tagihanDuplikat.map(i => i.id)

    let adaSewaLama = false

    if (list_id_tagihanDuplikat.length > 0) {

      const list_item_overlap = await TagihanItem.findAll({
        where: {
          tagihan_id: {
            [Op.in]: list_id_tagihanDuplikat
          }
        },
        transaction: t
      })

      adaSewaLama = list_item_overlap.some(
        i => i.tipe === "sewa"
      )
    }

    const adaSewaBaru = list_item.some(
      i => i.tipe === "sewa"
    )

    if (adaSewaLama && adaSewaBaru) {
      throwError(
        "Tagihan SEWA untuk periode ini sudah ada pada kontrak yang sama",
        400,
        "TAGIHAN_PERIODE_DUPLIKAT"
      )
    }

    // UPDATE TAGIHAN

    await tagihan.update({
      periode_awal,
      periode_akhir,
      jatuh_tempo,
      total_tagihan,
      catatan,
      lifecycle
    }, {
      transaction: t
    })

    // HAPUS SEMUA ITEM LAMA

    await TagihanItem.destroy({
      where: {
        tagihan_id: tagihan.id
      },
      transaction: t
    })

    // BUAT ULANG ITEM

    const list_item_created = await Promise.all(
      list_item.map(i =>
        TagihanItem.create({
          tagihan_id: tagihan.id,
          tipe: i.tipe,
          nama_item: i.nama_item,
          deskripsi: i.deskripsi ?? "",
          nominal: i.nominal
        }, {
          transaction: t
        })
      )
    )

    await t.commit()

    return {
      tagihan,
      list_item: list_item_created
    }

  } catch (error) {

    await t.rollback()

    throw error
  }
}

exports.hapus_tagihan = async (pemilik_id, tagihan_id) => {

  const t = await sequelize.transaction()

  try {

    // CEK PEMILIK

    const tagihan = await Tagihan.findOne({
      where: {
        id: tagihan_id
      },
      include: {
        model: Kontrak,
        required: true,
        include: {
          model: Kamar,
          required: true,
          include: {
            model: Kos,
            required: true,
            where: {
              pemilik_id: pemilik_id
            }
          }
        }
      },
      transaction: t,
      lock: t.LOCK.UPDATE
    })

    if (!tagihan) {
      throwError(
        "tagihan tidak ada atau bukan milik anda",
        404,
        "TAGIHAN_NOT_FOUND"
      )
    }

    if (tagihan.lifecycle === "cancelled") {
      throwError(
        "tagihan sudah dibatalkan",
        400,
        "TAGIHAN_ALREADY_CANCELLED"
      )
    }

    const pembayaran = await Pembayaran.findAll({
      where: {
        tagihan_id: tagihan.id
      },
      transaction: t
    })

    const total_dibayar = hitungTotalDibayar(pembayaran)

    pastikanBolehUbahTagihan({
      total_tagihan: tagihan.total_tagihan,
      total_dibayar,
    })

    // SOFT DELETE

    await tagihan.update({
      lifecycle: "cancelled"
    }, {
      transaction: t
    })

    await t.commit()

    return tagihan

  } catch (error) {

    await t.rollback()

    throw error
  }
}

