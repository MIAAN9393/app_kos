const { Op } = require("sequelize")
const Kamar = require("../model/kamar")
const Kontrak = require("../model/kontrak")
const { throwError } = require("../utils/error")

exports.FASILITAS_VALID = ["AC", "WiFi", "Lemari", "Kamar Mandi"]

exports.parseFasilitasResponse = (raw) => {
    if (raw == null) return null
    if (Array.isArray(raw)) {
        return raw.length > 0 ? raw : null
    }
    if (typeof raw === "string") {
        try {
            const parsed = JSON.parse(raw)
            if (Array.isArray(parsed) && parsed.length > 0) return parsed
        } catch (_) {
            return null
        }
    }
    return null
}

exports.validasiFasilitas = (raw) => {
    if (raw == null || raw === undefined) return null

    if (!Array.isArray(raw)) {
        throwError("fasilitas harus berupa array", 400, "VALIDATION_ERROR")
    }

    const out = []
    for (const item of raw) {
        const label = String(item ?? "").trim()
        if (!label) continue
        if (!exports.FASILITAS_VALID.includes(label)) {
            throwError(`fasilitas "${label}" tidak valid`, 400, "VALIDATION_ERROR")
        }
        if (!out.includes(label)) out.push(label)
    }

    return out.length > 0 ? out : null
}

// Satu sumber kebenaran: kontrak yang dianggap "sedang menghuni" kamar hari ini.
// Dipakai resetStatusKamar (badge kamar) maupun daftar penyewa per kamar/kos,
// supaya status hunian konsisten di semua page.
exports.kondisiKontrakMenghuni = () => {

    const today = new Date()
    today.setHours(0, 0, 0, 0)

    return {
        status: {[Op.in]:["aktif","pending"]},
        tanggal_mulai: { [Op.lte]: today },
        [Op.or]: [
            { tanggal_selesai: { [Op.gte]: today } },
            { tanggal_selesai: null }
        ]
    }
}

exports.resetStatusKamar = async (kamar_id, transaction) => {

    const kamar = await Kamar.findOne({
        where: { id: kamar_id },
        transaction,
        lock: transaction.LOCK.UPDATE
    })

    if (!kamar) {
        throwError("kamar tidak ditemukan", 404, "KAMAR_NOT_FOUND")
    }

    const jumlahPenghuni = await Kontrak.count({
        where: {
            kamar_id: kamar_id,
            ...exports.kondisiKontrakMenghuni()
        },
        transaction
    })

    let status_kondisi = "kosong"

    if (jumlahPenghuni >= kamar.kapasitas) {
        status_kondisi = "penuh"
    } else if (jumlahPenghuni > 0) {
        status_kondisi = "sebagian"
    }

    await kamar.update(
        { status_kondisi },
        { transaction }
    )
}
