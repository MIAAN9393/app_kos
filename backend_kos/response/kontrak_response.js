class KontrakResponse {

  constructor(kontrak) {

    if (!kontrak) return

    this.id = kontrak.id
    const kode =
      kontrak.kode_kontrak ??
      (typeof kontrak.get === "function" ? kontrak.get("kode_kontrak") : null)
    this.kode_kontrak = kode != null && String(kode).trim() !== "" ? String(kode).trim() : null
    this.public_token = kontrak.public_token

    this.penyewa_id = kontrak.penyewa_id
    this.kamar_id = kontrak.kamar_id

    this.tanggal_mulai = kontrak.tanggal_mulai
    this.tanggal_selesai = kontrak.tanggal_selesai

    this.harga_sewa = kontrak.harga_sewa
    this.siklus = kontrak.siklus

    this.status = kontrak.status

    this.dibuat_pada = kontrak.dibuat_pada
    this.diperbarui_pada = kontrak.diperbarui_pada

    // OPTIONAL RELATION

    this.penyewa = kontrak.Penyewa ? {
      id: kontrak.Penyewa.id,
      nama: kontrak.Penyewa.nama
    } : null

    this.kamar = kontrak.Kamar ? {
      id: kontrak.Kamar.id,
      nomor: kontrak.Kamar.nomor,
      kos_id: kontrak.Kamar.kos_id
    } : null

  }

  static list(list_kontrak = []) {

    return list_kontrak.map((kontrak) => {
      return new KontrakResponse(kontrak)
    })

  }

}

module.exports = KontrakResponse
