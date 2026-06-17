const kosService = require("../services/kos_service")

exports.ambil_kos = async (req,res,next) => {
    try {
        
        const data = await kosService.ambil_kos(req.user.id)

        res.status(200).json({
            success:true,
            code: "KOS_LIST_SUCCESS",
            pesan: "ini daftar kos kamu",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.buat_kos = async (req,res,next) => {

    try {

        const data = await kosService.buat_kos(req.user.id,req.body)

        res.status(200).json({
            success:true,
            code: "KOS_CREATED",
            pesan:"kos berhasil di buat",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.edit_kos = async (req,res,next) => {

    try {

        const data = await kosService.edit_kos(req.user.id,req.params.id,req.body)

        res.status(200).json({
            success:true,
            code: "KOS_UPDATED",
            pesan:"kos berhasil di update",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.shapus_kos = async (req,res,next) => {

    try {

        const data = await kosService.shapus_kos(req.user.id,req.params.id)

        res.status(200).json({
            success:true,
            code: "KOS_DELETED",
            pesan:"kos berhasil di hapus",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.laporan_kos = async (req,res,next) => {

    try {

        const kos_id = req.query.kos_id

        const data = await kosService.laporan_kos(req.user.id, kos_id)

        res.status(200).json({
            success:true,
            code: "KOS_LAPORAN_SUCCESS",
            pesan: "laporan kos",
            data
        })

    } catch (error) {
        next(error)
    }
}