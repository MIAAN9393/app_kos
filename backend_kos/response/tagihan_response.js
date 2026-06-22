class TagihanResponse {
  constructor(tagihan, items = [], total_dibayar = 0) {

    if (!tagihan) return

    this.id = tagihan.id
    this.kode_tagihan = tagihan.kode_tagihan
    this.public_token = tagihan.public_token

    // KONTEKS RELASI (terisi bila relasi Kontrak di-include, mis. ambil_semua_tagihan)
    this.kontrak_id = tagihan.kontrak_id
    this.penyewa_id = tagihan.Kontrak ? tagihan.Kontrak.penyewa_id : null
    this.kamar_id = tagihan.Kontrak ? tagihan.Kontrak.kamar_id : null

    this.periode_awal = tagihan.periode_awal
    this.periode_akhir = tagihan.periode_akhir

    this.jatuh_tempo = tagihan.jatuh_tempo

    this.total_tagihan = tagihan.total_tagihan
    this.total_dibayar = total_dibayar

    this.lifecycle = tagihan.lifecycle
    this.status_pembayaran = tagihan.status_pembayaran

    this.catatan = tagihan.catatan

    this.items = items.map((item) => ({
      id: item.id,
      tipe: item.tipe,
      nama_item: item.nama_item,
      deskripsi: item.deskripsi,
      nominal: item.nominal,
      event_date: item.event_date,
    }))

    this.dibuat_pada = tagihan.dibuat_pada
    this.diperbarui_pada = tagihan.diperbarui_pada
  }

  static list(list_tagihan = [], list_item = [], dibayar_map = {}) {

    const item_map = {}

    for (const item of list_item) {
      
      if(!item_map[item.tagihan_id]){
        item_map[item.tagihan_id] = []
      }

      item_map[item.tagihan_id].push(item)
    }

    return list_tagihan.map((tagihan) => {

      return new TagihanResponse(
        tagihan,
        item_map[tagihan.id]||[],
        dibayar_map[tagihan.id] || 0
      )

    })

  }
}

module.exports = TagihanResponse
