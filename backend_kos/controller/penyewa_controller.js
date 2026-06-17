const PenyewaService = require("../services/penyewa_service");
const PenyewaResponse = require("../response/penyewa_response");

exports.ambil_penyewa = async (req,res,next) => {

  const pemilik_id = req.user.id
  const kamar_id = req.params.id

    try {
        
        const data = await PenyewaService.ambil_penyewa(pemilik_id,kamar_id)

        res.status(200).json({
            success:true,
            code: "PENYEWA_LIST_SUCCESS",
            pesan: "ini daftar penyewa kamu",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.list_by_kos = async (req,res,next) => {

  const pemilik_id = req.user.id
  const kos_id = req.params.id

    try {
        
        const data = await PenyewaService.list_by_kos(pemilik_id, kos_id)

        res.status(200).json({
            success:true,
            code: "PENYEWA_BY_KOS_SUCCESS",
            pesan: "ini daftar penyewa per kos",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.buat_penyewa = async (req,res,next) => {

  const pemilik_id = req.user.id
  const body = req.body

  try {
    
    const penyewa = await PenyewaService.buat_penyewa(pemilik_id,body)

        res.status(200).json({
            success:true,
            code: "PENYEWA_CREATED",
            pesan:"penyewa berhasil di buat",
            data: new PenyewaResponse(penyewa)
        })
    
  } catch (error) {
    next(error)
  }

}

exports.edit_penyewa = async (req,res,next) => {

  const pemilik_id = req.user.id
  const penyewa_id = req.params.id
  const body = req.body

    try {

        const data = await PenyewaService.edit_penyewa(pemilik_id,penyewa_id,body)

        res.status(200).json({
            success:true,
            code: "PENYEWA_UPDATED",
            pesan:"penyewa berhasil di update",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.shapus_penyewa = async (req,res,next) => {

  const pemilik_id = req.user.id
  const penyewa_id = req.params.id

    try {

        const data = await PenyewaService.shapus_penyewa(pemilik_id,penyewa_id)

        res.status(200).json({
            success:true,
            code: "PENYEWA_DELETED",
            pesan:"penyewa berhasil di hapus",
            data
        })

    } catch (error) {
        next(error)
    }
}

exports.ambil_semua_penyewa = async (req,res,next) => {

  const pemilik_id = req.user.id

    try {
        
        const data = await PenyewaService.ambil_semua_penyewa(pemilik_id)

        res.status(200).json({
            success:true,
            code: "PENYEWA_LIST_SUCCESS",
            pesan: "ini daftar penyewa kamu",
            data
        })

    } catch (error) {
        next(error)
    }
}