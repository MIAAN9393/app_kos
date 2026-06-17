class LaporanKeuanganResponse {
  constructor(payload) {
    this.periode = payload.periode
    this.keuangan = payload.keuangan
    this.transaksi = payload.transaksi
  }

  static build(data) {
    return {
      periode: data.periode,
      keuangan: data.keuangan,
      transaksi: data.transaksi,
    }
  }
}

module.exports = LaporanKeuanganResponse
