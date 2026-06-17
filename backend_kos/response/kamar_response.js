const { parseFasilitasResponse } = require("../utils/kamar_helper")

class KamarResponse {

  constructor(kamar) {

    if (!kamar) return

    this.id = kamar.id

    this.kos_id = kamar.kos_id

    this.nomor = kamar.nomor

    this.harga = kamar.harga
    this.kapasitas = kamar.kapasitas

    this.status_kondisi = kamar.status_kondisi
    this.status = kamar.status
    this.fasilitas = parseFasilitasResponse(kamar.fasilitas)

    // OPTIONAL RELATION

    this.kos = kamar.Kos ? {
      id: kamar.Kos.id,
      nama_kos: kamar.Kos.nama_kos
    } : null

  }

  static list(list_kamar = []) {

    return list_kamar.map((kamar) => {
      return new KamarResponse(kamar)
    })

  }

}

module.exports = KamarResponse