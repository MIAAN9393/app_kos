const sequelize = require("../config/database")
const kamar = require("../model/kamar")
const Kontrak = require("../model/kontrak")
const Kos = require("../model/kos")
const Pembayaran = require("../model/pembayaran")
const Tagihan = require("../model/tagihan")
const TagihanItem = require("../model/tagihan_item")
const { throwError } = require("../utils/error")
const { validasi_pembayaran, validasi_refund } = require("../validator/pembayaran_validator")
const PembayaranResponse = require("../response/pembayaran_respon")
const { sync_status_pembayaran } = require("../utils/tagihan_helper")


exports.ambil_pembayaran = async (pemilik_id,tagihan_id)=>{

  const t = await sequelize.transaction()

  try {

    //CEK PEMILIK
      
    const tagihan = await Tagihan.findOne({
        where:{
          id: tagihan_id,
        },
        include: {
          model: Kontrak,
          required: true,
          include:{
            model: kamar,
            required: true,
            include:{
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
      }
    )

    //VALIDASI DATA

    if (!tagihan) {
      throwError(
        400,
        "tagihan tidak ada atau bukan milik anda",
        "TAGIHAN_NOT_FOUND",
      );
    }

    //AKSI

    const pembayaran = await Pembayaran.findAll({
      where: {
        tagihan_id: tagihan_id
      }
    })

    await t.commit()

    return PembayaranResponse.list(pembayaran)
    
  } catch (error) {
    
    await t.rollback()

    throw error
  }

}

exports.ambil_semua_pembayaran = async (pemilik_id) => {

  // VALIDASI

  if (!pemilik_id) {
    throwError(401, "pemilik tidak ditemukan", "UNAUTHORIZED")
  }

  // AMBIL SEMUA PEMBAYARAN MILIK PEMILIK (Pembayaran -> Tagihan -> Kontrak -> Kamar -> Kos)

  const list_pembayaran = await Pembayaran.findAll({
    include: {
      model: Tagihan,
      required: true,
      include: {
        model: Kontrak,
        required: true,
        include: {
          model: kamar,
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
    },
    order: [["id", "DESC"]]
  })

  // Daftar datar (tiap item membawa tagihan_id) supaya frontend bisa kelompokkan.
  return list_pembayaran.map((pembayaran) => new PembayaranResponse(pembayaran))
}

exports.buat_pembayaran = async (pemilik_id,body)=>{

  const {
    tagihan_id,
    jumlah_bayar,
  } = validasi_pembayaran(body)

  const t = await sequelize.transaction()

  try {

        //CEK PEMILIK
      
    const tagihan = await Tagihan.findOne({
        where:{
          id: tagihan_id,
        },
        include: {
          model: Kontrak,
          required: true,
          include:{
            model: kamar,
            required: true,
            include:{
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
      }
    )

    //VALIDASI DATA

    if (!tagihan) {
      throwError(
        400,
        "tagihan tidak ada atau bukan milik anda",
        "TAGIHAN_NOT_FOUND",
      );
    }

    const list_item = await TagihanItem.findAll({
      where: {
        tagihan_id: tagihan_id
      },
      transaction: t
    })

    if(!list_item || list_item.length == 0){
      throwError(
        400,
        "tagihan ini tidak memiliki list item",
        "LIST_ITEM_NOT_FOUND",
      );
    }

    if (tagihan.status_pembayaran === "lunas") {
      throwError(
        400,
        "tagihan ini sudah lunas tidak bisa melakukan pembayaran lagi",
        "TAGIHAN_PASSED",
      );
    }
    
    const total_tagihan = list_item.reduce((total, item) =>
    item.tipe == "diskon" ? total - item.nominal : total + item.nominal
    ,0);
    
    const total_nominal_transaksi = await Pembayaran.findAll({
      where: {
        tagihan_id: tagihan_id,
      },
      transaction: t
    })



    const total_bayar = total_nominal_transaksi.reduce(
      (total, pembayaran) =>
        pembayaran.status == "refund"? total - pembayaran.jumlah_bayar:
        total + pembayaran.jumlah_bayar,
      0
    )

    const sisa = (total_tagihan - total_bayar)

    if(jumlah_bayar > sisa){
      throwError(400,`nominal pembayaran berlebih, sisa hanya tinggal ${sisa}`)
    }
    //AKSI

    const pembayaran = await Pembayaran.create({
        tagihan_id:tagihan_id,
        jumlah_bayar:jumlah_bayar
      }, 
      {transaction: t}
    )

    await sync_status_pembayaran(tagihan_id, t)

    await t.commit()

    return pembayaran

  } catch (error) {
    
    await t.rollback()

    throw error
  }
}


exports.buat_refund_pembayaran = async (
  pemilik_id,
  body
) => {

  // VALIDASI INPUT

  const {
    pembayaran_id,
    jumlah_refund
  } = validasi_refund(body)

  const t = await sequelize.transaction()

  try {

    // CEK PEMILIK

    const pembayaran = await Pembayaran.findOne({
      where: {
        id: pembayaran_id,
        status: "valid"
      },
      include: {
        model: Tagihan,
        required: true,
        include: {
          model: Kontrak,
          required: true,
          include: {
            model: kamar,
            required: true,
            include: {
              model: Kos,
              required: true,
              where: {
                pemilik_id
              }
            }
          }
        }
      },
      transaction: t,
      lock: t.LOCK.UPDATE
    })

    // VALIDASI DATA

    if (!pembayaran) {
      throwError(
        400,
        "pembayaran tidak ditemukan atau bukan milik anda",
        "PEMBAYARAN_NOT_FOUND"
      )
    }

    const tagihan = await Tagihan.findOne({
      where: {
        id: pembayaran.tagihan_id
      }
    })

    if(tagihan.status_pembayaran == "lunas"){
      throwError("tagihan sudah di lunas",403,"REFUND FORBIDEN")
    }

    if(pembayaran.pembayaran_ref_id != null){
      throwError("pembayaran sudah di refund",403,"REFUND FORBIDEN")
    }

    const total_refund =
      await Pembayaran.sum(
        "jumlah_bayar",
        {
          where: {
            pembayaran_ref_id: pembayaran.id,
            status: "refund"
          },
          transaction: t
        }
      ) || 0

    const sisa_refund =
      pembayaran.jumlah_bayar - total_refund

    if (jumlah_refund > sisa_refund) {
      throwError(
        400,
        `maksimal refund ${sisa_refund}`,
        "REFUND_EXCEEDED"
      )
    }

    // AKSI

    const refund = await Pembayaran.create({
      tagihan_id: pembayaran.tagihan_id,
      jumlah_bayar: jumlah_refund,
      status: "refund",
      pembayaran_ref_id: pembayaran.id
    }, {
      transaction: t
    })

    await sync_status_pembayaran(pembayaran.tagihan_id, t)

    await t.commit()

    return refund

  } catch (error) {

    await t.rollback()

    throw error

  }
}