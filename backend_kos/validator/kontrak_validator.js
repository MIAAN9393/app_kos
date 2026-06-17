const { throwError } = require("../utils/error")

exports.validasi_kontrak = async (body) => {

    const {
        penyewa_id,
        kamar_id,
        tanggal_mulai,
        tanggal_selesai,
        harga_sewa,
        siklus
    } = body


    // VALIDASI FIELD WAJIB
    if (!penyewa_id) {
        throwError(400, "penyewa_id wajib diisi")
    }

    if (!kamar_id) {
        throwError(400, "kamar_id wajib diisi")
    }

    if (!tanggal_mulai) {
        throwError(400, "tanggal_mulai wajib diisi")
    }

    if (!tanggal_selesai) {
        throwError(400, "tanggal_selesai wajib diisi")
    }

    if (!harga_sewa) {
        throwError(400, "harga_sewa wajib diisi")
    }

    if (!siklus) {
        throwError(400, "siklus wajib diisi")
    }


    // VALIDASI SIKLUS
    const siklus_valid = ["harian", "mingguan", "bulanan", "tahunan"]

    if (!siklus_valid.includes(siklus)) {
        throwError(400, "siklus tidak valid")
    }


    // VALIDASI TANGGAL
    const sekarang = new Date()
    const mulai = new Date(tanggal_mulai)
    const selesai = new Date(tanggal_selesai)

    if (isNaN(mulai.getTime())) {
        throwError(400, "tanggal_mulai tidak valid")
    }

    if (isNaN(selesai.getTime())) {
        throwError(400, "tanggal_selesai tidak valid")
    }

    if(sekarang >= selesai) {
        throwError(400, "tanggal_selesai tidak boleh sekarang atau sebelum sekarang")
    }

    if (mulai >= selesai) {
        throwError(400, "tanggal_mulai harus sebelum tanggal_selesai")
    }

    //VALIDASI STATUS
    let status

    if (sekarang < mulai) status = "pending"
    if (sekarang >= mulai && sekarang <= selesai) status = "aktif"


    // VALIDASI HARGA
    if (harga_sewa <= 0) {
        throwError(400, "harga_sewa harus lebih dari 0")
    }


    // RETURN DATA BERSIH
    return {
        penyewa_id,
        kamar_id,
        tanggal_mulai,
        tanggal_selesai,
        harga_sewa,
        siklus,
        status
    }

}