const { validateWhatsAppNumber } = require("../utils/phone_helper")

function whatsappStatus(noTelpon) {
  if (!noTelpon || String(noTelpon).trim() === "") {
    return {
      valid: false,
      normalized: null,
      status: "belum_tersedia",
    }
  }

  try {
    const normalized = validateWhatsAppNumber(noTelpon)
    if (!normalized) {
      return {
        valid: false,
        normalized: null,
        status: "belum_tersedia",
      }
    }

    return {
      valid: true,
      normalized,
      status: "valid",
    }
  } catch (_) {
    return {
      valid: false,
      normalized: null,
      status: "tidak_valid",
    }
  }
}

class PenyewaResponse {

  constructor(penyewa) {

    if (!penyewa) return

    this.id = penyewa.id

    this.pemilik_id = penyewa.pemilik_id

    this.nama = penyewa.nama
    this.tanggal_lahir = penyewa.tanggal_lahir
    this.jenis_kelamin = penyewa.jenis_kelamin
    this.status_hubungan = penyewa.status_hubungan
    this.no_telpon = penyewa.no_telpon
    this.whatsapp = whatsappStatus(penyewa.no_telpon)
    this.email = penyewa.email

    this.status = penyewa.status

    this.dibuat_pada = penyewa.dibuat_pada

  }

  static list(list_penyewa = []) {

    return list_penyewa.map((penyewa) => {
      return new PenyewaResponse(penyewa)
    })

  }

}

module.exports = PenyewaResponse
