class PembayaranResponse {
  constructor(pembayaran) {

    if (!pembayaran) return

    this.id = pembayaran.id

    this.tagihan_id = pembayaran.tagihan_id
    this.jumlah_bayar = pembayaran.jumlah_bayar

    this.status = pembayaran.status

    this.pembayaran_ref_id = pembayaran.pembayaran_ref_id

    this.dibuat_pada = pembayaran.dibuat_pada
    this.dibatalkan_pada = pembayaran.dibatalkan_pada
  }

  static list(list_pembayaran = []) {

    return {

      list: list_pembayaran.map((pembayaran) => {
        return new PembayaranResponse(pembayaran)
      }),

      total_di_bayar: list_pembayaran.reduce((total, pembayaran) => {

        return total + pembayaran.jumlah_bayar

      }, 0)

    }

  }
}

module.exports = PembayaranResponse