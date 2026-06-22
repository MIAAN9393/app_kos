// Pastikan relasi Sequelize (Kontrak–Kamar–Kos) terdaftar
require("../model/index")

const { Op } = require("sequelize")
const Tagihan = require("../model/tagihan")
const Pembayaran = require("../model/pembayaran")
const { throwError } = require("../utils/error")
const { validasi_query_laporan } = require("../validator/laporan_validator")
const {
  rentangTanggalDariBulan,
  labelPeriode,
  ambil_kontrak_ids_pemilik,
  agregatTagihanPerStatusDenganSisa,
  agregatPembayaran,
  kelompokkanPembayaranPerTagihan,
  hitungTotalPiutang,
  hitungTotalNominalPenuh,
} = require("../utils/laporan_helper")

async function ambil_pembayaran_map_untuk_tagihan(tagihan_ids) {
  if (!tagihan_ids.length) return {}
  const rows = await Pembayaran.findAll({
    where: { tagihan_id: { [Op.in]: tagihan_ids } },
    attributes: ["tagihan_id", "jumlah_bayar", "status"],
    raw: true,
  })
  return kelompokkanPembayaranPerTagihan(rows)
}

/** Piutang aktual dalam rentang jatuh tempo terpilih (total − pembayaran net). */
async function hitung_total_sisa_piutang(kontrak_ids, tanggal_awal, tanggal_akhir) {
  if (!kontrak_ids.length) return 0

  const tagihan_rows = await Tagihan.findAll({
    where: {
      kontrak_id: { [Op.in]: kontrak_ids },
      lifecycle: "issued",
      jatuh_tempo: {
        [Op.between]: [tanggal_awal, tanggal_akhir],
      },
    },
    attributes: ["id", "total_tagihan"],
    raw: true,
  })

  const tagihan_ids = tagihan_rows.map((r) => r.id)
  const pembayaran_map = await ambil_pembayaran_map_untuk_tagihan(tagihan_ids)
  return hitungTotalPiutang(tagihan_rows, pembayaran_map)
}
const LaporanKeuanganResponse = require("../response/laporan_keuangan_response")
const LaporanTagihanResponse = require("../response/laporan_tagihan_response")
const { ambil_tanggal_doang } = require("../utils/waktu")

/**
 * LAPORAN TAGIHAN
 * -----------------
 * Menjawab: "tagihan apa yang jatuh tempo pada bulan tersebut?"
 *
 * Aturan:
 * - Tagihan masuk bulan berdasarkan kolom `jatuh_tempo` (bukan tanggal bayar).
 * - Jika dibayar sebelum jatuh tempo, tetap masuk bulan jatuh_tempo; status tetap mengikuti DB (bisa lunas).
 * - Hanya tagihan lifecycle `issued` (bukan draft / cancelled).
 */
exports.ambil_laporan_tagihan = async (pemilik_id, query) => {
  const { bulan_mulai, bulan_akhir, kos_ids } = validasi_query_laporan(query)
  const { tanggal_awal, tanggal_akhir } = rentangTanggalDariBulan(
    bulan_mulai,
    bulan_akhir
  )

  const kontrak_ids = await ambil_kontrak_ids_pemilik(pemilik_id, kos_ids)

  if (kontrak_ids.length === 0) {
    return LaporanTagihanResponse.build({
      periode: {
        bulan_mulai,
        bulan_akhir,
        label: labelPeriode(bulan_mulai, bulan_akhir),
        tanggal_awal,
        tanggal_akhir,
      },
      tagihan: {
        total_tagihan: 0,
        total_nominal_tagihan: 0,
        total_nominal_penuh: 0,
        lunas: { jumlah: 0, nominal: 0 },
        sebagian: { jumlah: 0, nominal: 0 },
        belum_bayar: { jumlah: 0, nominal: 0 },
        telat: { jumlah: 0, nominal: 0 },
      },
    })
  }

  const tagihan_rows = await Tagihan.findAll({
    where: {
      kontrak_id: { [Op.in]: kontrak_ids },
      lifecycle: "issued",
      jatuh_tempo: {
        [Op.between]: [tanggal_awal, tanggal_akhir],
      },
    },
    attributes: [
      "id",
      "kode_tagihan",
      "jatuh_tempo",
      "periode_awal",
      "periode_akhir",
      "total_tagihan",
      "status_pembayaran",
    ],
    order: [["jatuh_tempo", "ASC"]],
    raw: true,
  })

  const tagihan_ids = tagihan_rows.map((r) => r.id)
  const pembayaran_map = await ambil_pembayaran_map_untuk_tagihan(tagihan_ids)
  const agregat = agregatTagihanPerStatusDenganSisa(tagihan_rows, pembayaran_map)

  return LaporanTagihanResponse.build({
    periode: {
      bulan_mulai,
      bulan_akhir,
      label: labelPeriode(bulan_mulai, bulan_akhir),
      tanggal_awal,
      tanggal_akhir,
      dasar_perhitungan: "jatuh_tempo",
    },
    tagihan: {
      total_tagihan: agregat.total_tagihan,
      total_nominal_tagihan: agregat.total_nominal_tagihan,
      total_nominal_penuh: hitungTotalNominalPenuh(tagihan_rows),
      lunas: agregat.per_status.lunas,
      sebagian: agregat.per_status.sebagian,
      belum_bayar: agregat.per_status.belum_bayar,
      telat: agregat.per_status.telat,
    },
  })
}

/**
 * LAPORAN KEUANGAN
 * ----------------
 * Menjawab: "uang berapa yang masuk pada bulan tersebut?"
 *
 * Aturan:
 * - Pembayaran masuk bulan berdasarkan tanggal uang diterima.
 * - Di DB saat ini memakai `pembayaran.dibuat_pada` sebagai tanggal_bayar.
 * - Hanya pembayaran pada tagihan milik pemilik (issued).
 * - Valid = uang masuk; Refund = pengurangan / pengembalian.
 */
exports.ambil_laporan_keuangan = async (pemilik_id, query) => {
  const { bulan_mulai, bulan_akhir, kos_ids } = validasi_query_laporan(query)
  const { tanggal_awal, tanggal_akhir } = rentangTanggalDariBulan(
    bulan_mulai,
    bulan_akhir
  )

  const kontrak_ids = await ambil_kontrak_ids_pemilik(pemilik_id, kos_ids)

  if (kontrak_ids.length === 0) {
    return LaporanKeuanganResponse.build({
      periode: {
        bulan_mulai,
        bulan_akhir,
        label: labelPeriode(bulan_mulai, bulan_akhir),
        tanggal_awal,
        tanggal_akhir,
        dasar_perhitungan: "tanggal_bayar",
      },
      keuangan: {
        total_uang_masuk: 0,
        total_yang_sisa: 0,
        total_bayaran_bulan_depan: 0
      },
      transaksi: {
        total_pembayaran: 0,
        valid: { jumlah: 0, nominal: 0 },
        refund: { jumlah: 0, nominal: 0 },
      },
    })
  }

  const tagihan_ids_rows = await Tagihan.findAll({
    attributes: ["id","jatuh_tempo"],
    where: {
      kontrak_id: { [Op.in]: kontrak_ids },
      lifecycle: "issued",
    },
    raw: true,
  })

  const tagihan_ids = tagihan_ids_rows.map((r) => r.id)

  if (tagihan_ids.length === 0) {
    return LaporanKeuanganResponse.build(emptyKeuangan(bulan_mulai, bulan_akhir, tanggal_awal, tanggal_akhir))
  }

  // Filter pembayaran: tanggal_bayar (dibuat_pada) dalam rentang bulan
  // tanggal_bayar = dibuat_pada (waktu transaksi tercatat)
  const pembayaran_rows = await Pembayaran.findAll({
    where: {
      tagihan_id: { [Op.in]: tagihan_ids },
      dibuat_pada: {
        [Op.between]: [
          `${tanggal_awal} 00:00:00`,
          `${tanggal_akhir} 23:59:59`,
        ],
      },
    },
    attributes: ["id", "tagihan_id", "jumlah_bayar", "status", "dibuat_pada"],
    raw: true,
  })

  const agregat = agregatPembayaran(pembayaran_rows)

  //sortir pembayaran untuk tagihan masa periode atau bulan depan
  
  const tagihan_id_bulan_depan = new Set();
  const tagihan_id_masa_periode = new Set();

  for (const tagihan of tagihan_ids_rows) {
    if (tagihan.jatuh_tempo > tanggal_akhir) {
      tagihan_id_bulan_depan.add(tagihan.id);
    } else {
      tagihan_id_masa_periode.add(tagihan.id);
    }
  }

  let total_bayaran_bulan_depan = 0;
  let total_bayaran_masa_periode = 0;

  for (const pembayaran of pembayaran_rows) {
    if (tagihan_id_bulan_depan.has(pembayaran.tagihan_id)) {

      if(pembayaran.status == "valid") {
        total_bayaran_bulan_depan += pembayaran.jumlah_bayar;
      } else total_bayaran_bulan_depan -= pembayaran.jumlah_bayar;

    } else {

      if(pembayaran.status == "valid") {
        total_bayaran_masa_periode += pembayaran.jumlah_bayar;
      } else total_bayaran_masa_periode -= pembayaran.jumlah_bayar;
    }
  }


  // console.log("TAGIHAN ID MASA DEPAN",tagihan_id_bulan_depan)
  // console.log("TAGIHAN ID MASA PERIODE",tagihan_id_masa_periode)
  // console.log("TAGIHAN UANG MASA DEPAN",total_bayaran_bulan_depan)
  // console.log("TAGIHAN UANG MASA PERIODE",total_bayaran_masa_periode)


  // Total sisa = piutang aktual pada tagihan jatuh tempo di rentang filter.
  const total_yang_sisa = await hitung_total_sisa_piutang(
    kontrak_ids,
    tanggal_awal,
    tanggal_akhir
  )
  const total_nominal_transaksi = agregat.per_status.valid.nominal + agregat.per_status.refund.nominal

  return LaporanKeuanganResponse.build({
    periode: {
      bulan_mulai,
      bulan_akhir,
      label: labelPeriode(bulan_mulai, bulan_akhir),
      tanggal_awal,
      tanggal_akhir,
      dasar_perhitungan: "tanggal_bayar",
      catatan_tanggal_bayar: "Menggunakan kolom pembayaran.dibuat_pada sebagai tanggal_bayar",
    },
    keuangan: {
      total_uang_bersih: Number(agregat.total_uang_masuk-agregat.total_refund),
      total_uang_masuk: Number(agregat.total_uang_masuk) || 0,
      total_yang_sisa: Number(total_yang_sisa) || 0,
      total_sisa_piutang: Number(total_yang_sisa) || 0,
      total_bayaran_masa_periode: Number(total_bayaran_masa_periode) || 0,
      total_bayaran_bulan_depan: Number(total_bayaran_bulan_depan) || 0
    },
    transaksi: {
      total_pembayaran: agregat.total_pembayaran,
      total_nominal_transaksi: Number(total_nominal_transaksi),
      valid: agregat.per_status.valid,
      refund: agregat.per_status.refund,
    },
  })
}

function emptyKeuangan(bulan_mulai, bulan_akhir, tanggal_awal, tanggal_akhir) {
  return {
    periode: {
      bulan_mulai,
      bulan_akhir,
      label: labelPeriode(bulan_mulai, bulan_akhir),
      tanggal_awal,
      tanggal_akhir,
      dasar_perhitungan: "tanggal_bayar",
    },
    keuangan: {
      total_uang_masuk: 0,
      total_yang_sisa: 0,
    },
    transaksi: {
      total_pembayaran: 0,
      valid: { jumlah: 0, nominal: 0 },
      refund: { jumlah: 0, nominal: 0 },
    },
  }
}
