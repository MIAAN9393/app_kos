class LaporanTagihanResponse {
  constructor(payload) {
    this.periode = payload.periode
    this.tagihan = payload.tagihan
  }

  static build(data) {
    return {
      periode: data.periode,
      tagihan: data.tagihan,
    }
  }
}

module.exports = LaporanTagihanResponse
