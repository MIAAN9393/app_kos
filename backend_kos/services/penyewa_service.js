const Penyewa = require("../model/penyewa")
const sequelize = require("../config/database")
const { throwError } = require("../utils/error")
const PenyewaResponse = require("../response/penyewa_response")
const kamar = require("../model/kamar")
const Kos = require("../model/kos")
const { where, Op } = require("sequelize")
const Kontrak = require("../model/kontrak")
const { kondisiKontrakMenghuni } = require("../utils/kamar_helper")
const { validateWhatsAppNumber } = require("../utils/phone_helper")
const SubscriptionService = require("./subscription_service")

exports.ambil_penyewa = async (pemilik_id, kamar_id) => {

    // VALIDASI
    if (!pemilik_id) {
        throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
    }

    if (!kamar_id) {
        throwError("kamar tidak ditemukan", 400, "BAD_REQUEST")
    }

    // AMBIL KONTRAK YANG SEDANG MENGHUNI KAMAR INI
    const kontrak = await Kontrak.findAll({
        attributes: ["id", "penyewa_id", "tanggal_mulai", "tanggal_selesai", "status"],
        where: {
            kamar_id: kamar_id,
            ...kondisiKontrakMenghuni()
        },
        raw: true
    })

    // AMBIL ARRAY ID
    const penyewa_ids = kontrak.map(i => i.penyewa_id)
    const kontrak_by_penyewa = {}
    for (const row of kontrak) {
        kontrak_by_penyewa[row.penyewa_id] = row
    }

    // JIKA TIDAK ADA PENYEWA
    if (penyewa_ids.length === 0) {
        return []
    }

    // AMBIL DATA PENYEWA (digerakkan oleh kontrak, tidak bergantung status global penyewa)
    const list_penyewa = await Penyewa.findAll({
        where: {
            id: {
                [Op.in]: penyewa_ids
            },
            pemilik_id: pemilik_id
        }
    })

    return PenyewaResponse.list(list_penyewa).map((row) => {
        const k = kontrak_by_penyewa[row.id]
        if (k) {
            row.kontrak_id = k.id
            row.tanggal_mulai = k.tanggal_mulai
            row.tanggal_selesai = k.tanggal_selesai
            row.status_kontrak = k.status
        }
        return row
    })
}

exports.list_by_kos = async (pemilik_id, kos_id) => {

    if (!pemilik_id) {
        throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
    }

    if (!kos_id) {
        throwError("kos tidak ditemukan", 400, "BAD_REQUEST")
    }

    const kos = await Kos.findOne({
        where: {
            id: kos_id,
            pemilik_id: pemilik_id,
            status: "aktif"
        }
    })

    if (!kos) {
        throwError("kos tidak ditemukan atau bukan milik anda", 404, "KOS_NOT_FOUND")
    }

    const list_kamar = await kamar.findAll({
        where: {
            kos_id: kos_id,
            status: "aktif"
        },
        attributes: ["id"],
        raw: true
    })

    const kamar_ids = list_kamar.map(i => i.id)

    if (kamar_ids.length === 0) {
        return []
    }

    const kontrak_list = await Kontrak.findAll({
        where: {
            kamar_id: {
                [Op.in]: kamar_ids
            },
            ...kondisiKontrakMenghuni()
        },
        include: [{
            model: Penyewa,
            required: true,
            where: {
                pemilik_id: pemilik_id,
            }
        }]
    })

    return kontrak_list.map((kontrak) => {
        const row = new PenyewaResponse(kontrak.Penyewa)
        row.kamar_id = kontrak.kamar_id
        row.kontrak_id = kontrak.id
        row.tanggal_mulai = kontrak.tanggal_mulai
        row.tanggal_selesai = kontrak.tanggal_selesai
        row.status_kontrak = kontrak.status
        return row
    })
}

const JENIS_KELAMIN_VALID = ["pria", "wanita"]
const STATUS_HUBUNGAN_VALID = ["jomblo", "pacaran", "menikah", "duda", "janda"]

const nullableString = (value) => {
    if (value === undefined || value === null) return null
    const text = String(value).trim()
    return text === "" ? null : text
}

const wajibString = (value) => nullableString(value)

const validasiTanggal = (field, value) => {
    const text = nullableString(value)
    if (text === null) return null
    const cocok = /^(\d{4})-(\d{2})-(\d{2})$/.exec(text)
    if (!cocok) {
        throwError(`${field} tidak valid`, 400, "VALIDATION_ERROR")
    }
    const tanggal = new Date(Date.UTC(Number(cocok[1]), Number(cocok[2]) - 1, Number(cocok[3])))
    const valid =
        tanggal.getUTCFullYear() === Number(cocok[1]) &&
        tanggal.getUTCMonth() === Number(cocok[2]) - 1 &&
        tanggal.getUTCDate() === Number(cocok[3])
    if (!valid) {
        throwError(`${field} tidak valid`, 400, "VALIDATION_ERROR")
    }
    return text
}

const validasiEnum = (field, value, allowed) => {
    const text = nullableString(value)
    if (text === null) return null
    if (!allowed.includes(text)) {
        throwError(`${field} tidak valid`, 400, "VALIDATION_ERROR")
    }
    return text
}

exports.buat_penyewa = async (pemilik_id,body) => {

    const nama = wajibString(body.nama)
    const no_telpon = validateWhatsAppNumber(body.no_telpon)
    const email = wajibString(body.email)
    const tanggal_lahir = validasiTanggal("tanggal lahir", body.tanggal_lahir)
    const jenis_kelamin = validasiEnum("jenis kelamin", body.jenis_kelamin, JENIS_KELAMIN_VALID)
    const status_hubungan = validasiEnum("status hubungan", body.status_hubungan, STATUS_HUBUNGAN_VALID)

    // VALIDASI

    if (!nama || !email) {
        throwError("data tidak lengkap", 400, "VALIDATION_ERROR")
    }

    await SubscriptionService.assertCanCreatePenyewa(pemilik_id)

    // BUAT PENYEWA
    const penyewa = await Penyewa.create({
        pemilik_id:pemilik_id,
        nama,
        tanggal_lahir,
        jenis_kelamin,
        status_hubungan,
        no_telpon,
        email
    })

    return penyewa
}

exports.edit_penyewa = async (pemilik_id,penyewa_id,body)=>{

    const nama = wajibString(body.nama)
    const email = wajibString(body.email)
    const tanggal_lahir = validasiTanggal("tanggal lahir", body.tanggal_lahir)
    const jenis_kelamin = validasiEnum("jenis kelamin", body.jenis_kelamin, JENIS_KELAMIN_VALID)
    const status_hubungan = validasiEnum("status hubungan", body.status_hubungan, STATUS_HUBUNGAN_VALID)
    
    //VALIDASI
    if(!pemilik_id){
        throwError("pemilik tidak ditemukan",401,"UNAUTHORIZED")
    }

    if(!penyewa_id){
        throwError("penyewa tidak ditemukan",401,"UNAUTHORIZED")
    }

    if(!nama){
        throwError("data tidak lengkap",400,"VALIDATION_ERROR")
    }

    //AMBIL DATA PENYEWA
    const penyewa = await Penyewa.findOne({where:{id:penyewa_id,pemilik_id:pemilik_id,status:"aktif"}})

    if(!penyewa){   
        throwError("data penyewa tidak di temukan atau bukan milik anda",400,"PENYEWA_NOT_FOUND")
    }

    const adaNoTelpon = Object.prototype.hasOwnProperty.call(body, "no_telpon")
    const no_telpon = adaNoTelpon
        ? validateWhatsAppNumber(body.no_telpon)
        : penyewa.no_telpon

    //UPDATE DATA PENYEWA
    await penyewa.update({
        nama,
        tanggal_lahir: Object.prototype.hasOwnProperty.call(body, "tanggal_lahir") ? tanggal_lahir : penyewa.tanggal_lahir,
        jenis_kelamin: Object.prototype.hasOwnProperty.call(body, "jenis_kelamin") ? jenis_kelamin : penyewa.jenis_kelamin,
        status_hubungan: Object.prototype.hasOwnProperty.call(body, "status_hubungan") ? status_hubungan : penyewa.status_hubungan,
        no_telpon,
        email: email ?? penyewa.email
    })

    return new PenyewaResponse(penyewa)
}

exports.shapus_penyewa = async (pemilik_id,penyewa_id)=>{
    
    //VALIDASI
    if(!pemilik_id){
        throwError("pemilik tidak ditemukan",401,"UNAUTHORIZED")
    }

    if(!penyewa_id){
        throwError("penyewa tidak ditemukan",401,"UNAUTHORIZED")
    }

    //AMBIL DATA PENYEWA    
    const penyewa = await Penyewa.findOne({where:{id:penyewa_id,pemilik_id:pemilik_id,status:"aktif"}})

    if(!penyewa){   
        throwError("data penyewa tidak di temukan atau bukan milik anda",400,"PENYEWA_NOT_FOUND")
    }

    // VALIDASI KONSISTENSI — masih ada kontrak aktif/pending
    const jumlahKontrakBerjalan = await Kontrak.count({
        where: {
            penyewa_id: penyewa_id,
            status: { [Op.in]: ["aktif", "pending"] }
        }
    })

    if (jumlahKontrakBerjalan > 0) {
        throwError(
            "penyewa masih memiliki kontrak aktif atau pending, tidak bisa dihapus",
            403,
            "DELETE_PENYEWA_FORBIDDEN"
        )
    }

    //UPDATE DATA PENYEWA
    await penyewa.update({
        status:"nonaktif"
    })

    return penyewa
}

exports.ambil_semua_penyewa = async (pemilik_id) => {

    const list_penyewa = await Penyewa.findAll({
        where: {
            pemilik_id: pemilik_id
        }
    })

    if(list_penyewa.length == 0){
        return[]
    }

    return PenyewaResponse.list(list_penyewa)
}
