const { Op } = require("sequelize")
const Penyewa = require("../model/penyewa")
const Kontrak = require("../model/kontrak")

// Hitung ulang status penyewa berdasarkan kontraknya.
// Penyewa "aktif" jika masih punya kontrak berjalan/akan berjalan (aktif/pending),
// selain itu "nonaktif". Mencegah penyewa salah jadi nonaktif saat menyelesaikan
// satu kontrak padahal masih punya kontrak lain yang aktif.
exports.resetStatusPenyewa = async (penyewa_id, transaction) => {

    const jumlahKontrakBerjalan = await Kontrak.count({
        where: {
            penyewa_id,
            status: { [Op.in]: ["aktif", "pending"] }
        },
        transaction
    })

    const status = jumlahKontrakBerjalan > 0 ? "aktif" : "nonaktif"

    await Penyewa.update(
        { status },
        {
            where: { id: penyewa_id },
            transaction
        }
    )

    return status
}
