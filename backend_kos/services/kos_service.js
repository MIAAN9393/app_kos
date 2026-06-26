const Kos = require("../model/kos")
const sequelize = require("../config/database")
const { throwError } = require("../utils/error")
const KosResponse = require("../response/kos_response")
const Kamar = require("../model/kamar")
const Kontrak = require("../model/kontrak")
const Tagihan = require("../model/tagihan")
const Pembayaran = require("../model/pembayaran")
const { Op } = require("sequelize")
const SubscriptionService = require("./subscription_service")

exports.ambil_kos = async (pemilik_id)=>{
    try {
        //VALIDASI
        if(!pemilik_id){
            throwError("pemilik tidak ditemukan",401,"UNAUTHORIZED")
        }

        //AMBIL DATA KOS
        const list_kos = await Kos.findAll({where:{pemilik_id:pemilik_id,status:"aktif"}})

        if (list_kos.length === 0) {
            return KosResponse.list([])
        }

        const kos_ids = list_kos.map((k) => k.id)

        const kamar_rows = await Kamar.findAll({
            attributes: [
                "kos_id",
                [sequelize.fn("COUNT", sequelize.col("id")), "jumlah_kamar"],
            ],
            where: {
                kos_id: { [Op.in]: kos_ids },
                status: "aktif",
            },
            group: ["kos_id"],
            raw: true,
        })

        const kontrak_rows = await Kontrak.findAll({
            attributes: [
                [sequelize.col("kamar.kos_id"), "kos_id"],
                [
                    sequelize.fn(
                        "COUNT",
                        sequelize.fn("DISTINCT", sequelize.col("Kontrak.penyewa_id"))
                    ),
                    "jumlah_penyewa",
                ],
            ],
            include: [
                {
                    model: Kamar,
                    as: "kamar",
                    attributes: [],
                    where: {
                        kos_id: { [Op.in]: kos_ids },
                        status: "aktif",
                    },
                    required: true,
                },
            ],
            where: { status: "aktif" },
            group: [sequelize.col("kamar.kos_id")],
            raw: true,
        })

        const kamar_map = Object.fromEntries(
            kamar_rows.map((r) => [r.kos_id, Number(r.jumlah_kamar) || 0])
        )
        const penyewa_map = Object.fromEntries(
            kontrak_rows.map((r) => [r.kos_id, Number(r.jumlah_penyewa) || 0])
        )

        const enriched = list_kos.map((kos) => {
            const plain = kos.get ? kos.get({ plain: true }) : kos
            return {
                ...plain,
                jumlah_kamar: kamar_map[kos.id] ?? 0,
                jumlah_penyewa: penyewa_map[kos.id] ?? 0,
            }
        })

        return KosResponse.list(enriched)
    } catch (err) {
        console.error("KOS ERROR MESSAGE:", err.message)
        console.error("KOS ERROR NAME:", err.name)
        console.error("KOS SQL MESSAGE:", err.parent?.sqlMessage)
        console.error("KOS SQL:", err.parent?.sql)
        throw err
    }
}

exports.buat_kos = async (pemilik_id,body)=>{

    const { nama_kos, alamat, deskripsi } = body

    //VALIDASI
    if(!pemilik_id){
        throwError("pemilik tidak ditemukan",401,"UNAUTHORIZED")
    }

    if(!nama_kos || !alamat || !deskripsi){
        throwError("data tidak lengkap",400,"VALIDATION_ERROR")
    }

    await SubscriptionService.assertCanCreateKos(pemilik_id)

    const t = await sequelize.transaction()

    //BUAT DATA KOS
    try {
        
        const kos = await Kos.create({
            pemilik_id:pemilik_id,
            nama_kos:nama_kos,
            alamat:alamat,
            deskripsi:deskripsi
        },{transaction:t})

        await t.commit()

        return kos

    } catch (error) {
        await t.rollback()

        throw error

    } 

}

exports.edit_kos = async (pemilik_id,kos_id,body)=>{

    const {nama_kos,alamat,deskripsi} = body
    
    //VALIDASI
    if(!pemilik_id){
        throwError("pemilik tidak ditemukan",401,"UNAUTHORIZED")
    }

    if(!kos_id){
        throwError("kos tidak ditemukan",401,"UNAUTHORIZED")
    }

    if(!nama_kos||!alamat||!deskripsi){
        throwError("data tidak lengkap",400,"VALIDATION_ERROR")
    }

    //AMBIL DATA KOS
    const kos = await Kos.findOne({where:{id:kos_id,pemilik_id:pemilik_id}})

    if(!kos){
        throwError("data kos tidak di temukan atau bukan milik anda",400,"KOS_NOT_FOUND")
    }

    //UPDATE DATA KOS
    await kos.update(body)

    return kos
}

exports.shapus_kos = async (pemilik_id,kos_id)=>{
    
    //VALIDASI
    if(!pemilik_id){
        throwError("pemilik tidak ditemukan",401,"UNAUTHORIZED")
    }

    if(!kos_id){
        throwError("kos tidak ditemukan",401,"UNAUTHORIZED")
    }

    //AMBIL DATA KOS
    const kos = await Kos.findOne({where:{id:kos_id,pemilik_id:pemilik_id,status:"aktif"}})
    
    if(!kos){
        throwError("data kos tidak di temukan atau bukan milik anda",404,"KOS_NOT_FOUND")
    }

    //VALIDASI KONSISTENSI

    const kamar = await Kamar.count({
        where: {
            kos_id: kos_id
        }
    })

    if(kamar > 0){
        throwError("kos masih berisi tidak bisa di hapus",403,"DELETE_KOS_FORBIDDEN")
    }

    //UPDATE DATA KOS
    await kos.update({status:"nonaktif"})

    return kos
}

exports.laporan_kos = async (pemilik_id, kos_id) => {

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

    const kamars = await Kamar.findAll({
        where: {
            kos_id: kos_id,
            status: "aktif"
        }
    })

    let kamar_kosong = 0
    let kamar_sebagian = 0
    let kamar_penuh = 0

    for (const kamar of kamars) {
        if (kamar.status_kondisi === "kosong") kamar_kosong++
        else if (kamar.status_kondisi === "sebagian") kamar_sebagian++
        else if (kamar.status_kondisi === "penuh") kamar_penuh++
    }

    const kamar_ids = kamars.map(k => k.id)

    let penyewa_aktif = 0
    let tagihan_belum_lunas = 0
    let total_tagihan = 0
    let total_terbayar = 0

    if (kamar_ids.length > 0) {

        const kontrak_aktif = await Kontrak.findAll({
            where: {
                kamar_id: {
                    [Op.in]: kamar_ids
                },
                status: "aktif"
            },
            attributes: ["id", "penyewa_id"],
            raw: true
        })

        penyewa_aktif = new Set(kontrak_aktif.map(k => k.penyewa_id)).size

        const kontrak_ids = kontrak_aktif.map(k => k.id)

        if (kontrak_ids.length > 0) {

            const tagihans = await Tagihan.findAll({
                where: {
                    kontrak_id: {
                        [Op.in]: kontrak_ids
                    },
                    lifecycle: {
                        [Op.ne]: "cancelled"
                    }
                },
                attributes: ["id", "total_tagihan", "status_pembayaran"],
                raw: true
            })

            for (const tagihan of tagihans) {
                total_tagihan += Number(tagihan.total_tagihan) || 0
                if (tagihan.status_pembayaran !== "lunas") {
                    tagihan_belum_lunas++
                }
            }

            const tagihan_ids = tagihans.map(t => t.id)

            if (tagihan_ids.length > 0) {

                const pembayaran_rows = await Pembayaran.findAll({
                    attributes: ["status", "jumlah_bayar"],
                    where: {
                        tagihan_id: {
                            [Op.in]: tagihan_ids
                        }
                    },
                    raw: true
                })

                for (const row of pembayaran_rows) {
                    if (row.status === "valid") {
                        total_terbayar += Number(row.jumlah_bayar) || 0
                    }
                    if (row.status === "refund") {
                        total_terbayar -= Number(row.jumlah_bayar) || 0
                    }
                }
            }
        }
    }

    return [
        { label: "Total Kamar", value: kamars.length },
        { label: "Kamar Kosong", value: kamar_kosong },
        { label: "Kamar Sebagian", value: kamar_sebagian },
        { label: "Kamar Penuh", value: kamar_penuh },
        { label: "Penyewa Aktif", value: penyewa_aktif },
        { label: "Tagihan Belum Lunas", value: tagihan_belum_lunas },
        { label: "Total Tagihan", value: total_tagihan },
        { label: "Total Terbayar", value: total_terbayar },
        { label: "Sisa Piutang", value: total_tagihan - total_terbayar },
    ]
}
