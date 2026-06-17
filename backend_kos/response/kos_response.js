class KosResponse {

  constructor(kos) {

    if (!kos) return

    this.id = kos.id

    this.pemilik_id = kos.pemilik_id

    this.nama_kos = kos.nama_kos
    this.alamat = kos.alamat
    this.deskripsi = kos.deskripsi

    this.status = kos.status

    this.created_at = kos.created_at

    this.jumlah_kamar = Number(kos.jumlah_kamar) || 0
    this.jumlah_penyewa = Number(kos.jumlah_penyewa) || 0

  }

  static list(list_kos = []) {

    return list_kos.map((kos) => {
      return new KosResponse(kos)
    })

  }

}

module.exports = KosResponse