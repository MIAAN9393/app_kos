const Kamar = require("../model/kamar")
const sequelize = require("../config/database")
const { Op } = require("sequelize")
const { throwError } = require("../utils/error")
const Kos = require("../model/kos")
const KamarResponse = require("../response/kamar_response")
const { resetStatusKamar, validasiFasilitas } = require("../utils/kamar_helper")
const Kontrak = require("../model/kontrak")
const SubscriptionService = require("./subscription_service")

exports.ambil_kamar = async (pemilik_id, kos_id)=>{

    //VALIDASI
    if(!pemilik_id){
        throwError("pemilik tidak ditemukan",401,"UNAUTHORIZED")
    }

    //CEK KEPEMILIKAN
    const kos = await Kos.findOne({where:{id:kos_id,pemilik_id:pemilik_id}})

    if (!kos) {
        throwError("kos tidak ditemukan atau bukan milik anda", 404, "KOS_NOT_FOUND")
    }
    
    //AMBIL DATA KAMAR
    const list_kamar = await Kamar.findAll({where:{kos_id:kos.id,status:"aktif"}})

    return KamarResponse.list(list_kamar)
}

exports.buat_kamar = async (pemilik_id, kos_id, body) => {

    const { nomor, harga, kapasitas, fasilitas } = body

    // VALIDASI
    if (!pemilik_id) {
        throwError("user tidak terautentikasi", 401, "UNAUTHORIZED")
    }

    if (!kos_id) {
        throwError("kos_id tidak ditemukan", 400, "VALIDATION_ERROR")
    }

    if (!nomor || !harga || !kapasitas) {
        throwError("data tidak lengkap", 400, "VALIDATION_ERROR")
    }

    await SubscriptionService.assertCanCreateKamar(pemilik_id)

    const t = await sequelize.transaction()

    try {
        // CEK KEPEMILIKAN
        const kos = await Kos.findOne({
            where: {
                id: kos_id,
                pemilik_id: pemilik_id
            },
            transaction: t
        })

        if (!kos) {
            throwError("kos tidak ditemukan atau bukan milik anda", 404, "KOS_NOT_FOUND")
        }

        // BUAT KAMAR
        const fasilitasValid = validasiFasilitas(fasilitas)
        const kamar = await Kamar.create({
            kos_id,
            nomor,
            harga,
            kapasitas,
            fasilitas: fasilitasValid
        }, { transaction: t })

        await t.commit()

        return kamar
    } catch (error) {
        await t.rollback()
        throw(error)
    }
}

exports.edit_kamar = async (pemilik_id, kamar_id, body) => {

    const { nomor, harga, kapasitas, fasilitas } = body

    // VALIDASI
    if (!pemilik_id) {
        throwError("user tidak terautentikasi", 401, "UNAUTHORIZED")
    }

    if (!kamar_id) {
        throwError("kamar_id tidak ditemukan", 400, "VALIDATION_ERROR")
    }

    if (!nomor || !harga || !kapasitas) {
        throwError("data tidak lengkap", 400, "VALIDATION_ERROR")
    }

    const t = await sequelize.transaction()

    try {
       // AMBIL DATA KAMAR
        const kamar = await Kamar.findByPk(kamar_id)

        if (!kamar) {
            throwError("kamar tidak ditemukan", 404, "KAMAR_NOT_FOUND")
        }

        // CEK KEPEMILIKAN
        const kos = await Kos.findOne({
            where:{
                id:kamar.kos_id,
                pemilik_id:pemilik_id
            }
        })

        if (!kos) {
            throwError("kos tidak ditemukan atau bukan milik anda", 404, "KOS_NOT_FOUND")
        }

        //CEK KONSISTENSI
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

        if (kapasitas<jumlah_kontrak) {
          throwError("kapasitas tidak bisa di perkecil dari total penyewa yang ada sekarang", 400, "FORBIDDEN_EDIT_KAMAR")
        }

        // UPDATE DATA
        const fasilitasValid = validasiFasilitas(fasilitas)
        await kamar.update({
            nomor,
            harga,
            kapasitas,
            fasilitas: fasilitasValid
        })

        await resetStatusKamar(kamar_id,t)

        await t.commit()

        return kamar
    } catch (error) {
        
        await t.rollback()
        throw(error)
    }
}

exports.shapus_kamar = async (pemilik_id, kamar_id) => {

    //VALIDASI
    if (!pemilik_id) {
        throwError("user tidak terautentikasi", 401, "UNAUTHORIZED")
    }

    if (!kamar_id) {
        throwError("kamar_id tidak ditemukan", 400, "VALIDATION_ERROR")
    }

    const t = await sequelize.transaction()

    try {
        //AMBIL DATA KAMAR
        const kamar = await Kamar.findOne({
            where: { id: kamar_id, status: "aktif" },
            transaction: t
        })

        if (!kamar) {
            throwError("kamar tidak ditemukan", 404, "KAMAR_NOT_FOUND")
        }

        // CEK KEPEMILIKAN
        const kos = await Kos.findOne({
            where: {
                id: kamar.kos_id,
                pemilik_id: pemilik_id
            },
            transaction: t
        })

        if (!kos) {
            throwError("kos tidak ditemukan atau bukan milik anda", 404, "KOS_NOT_FOUND")
        }

        //VALIDASI KONSISTENSI
        const kontrak = await Kontrak.count({
            where: {
                kamar_id: kamar_id,
                status: { [Op.in]: ["aktif", "pending"] }
            },
            transaction: t
        })

        if(kontrak > 0) throwError("masih ada penyewa dan kontrak di kamar ini")

        //UPDATE DATA KAMAR
        await kamar.update({
            status: "nonaktif"
        }, { transaction: t })

        await t.commit()

        return kamar
    } catch (error) {
        await t.rollback()
        throw(error)
    }

}
