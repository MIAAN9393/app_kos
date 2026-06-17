require("../model/index")

const { Op } = require("sequelize")
const User = require("../model/user")
const Kos = require("../model/kos")
const Kamar = require("../model/kamar")
const Penyewa = require("../model/penyewa")
const Kontrak = require("../model/kontrak")
const Tagihan = require("../model/tagihan")
const Pembayaran = require("../model/pembayaran")
const { throwError } = require("../utils/error")

const NAMA_BULAN = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "Mei",
  "Jun",
  "Jul",
  "Agu",
  "Sep",
  "Okt",
  "Nov",
  "Des",
]

function pad2(value) {
  return String(value).padStart(2, "0")
}

function dateKey(date) {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`
}

function monthKey(date) {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}`
}

function monthRange(date) {
  const awal = new Date(date.getFullYear(), date.getMonth(), 1)
  const akhir = new Date(date.getFullYear(), date.getMonth() + 1, 0)
  return {
    bulan: monthKey(awal),
    label: `${NAMA_BULAN[awal.getMonth()]} ${awal.getFullYear()}`,
    tanggal_awal: dateKey(awal),
    tanggal_akhir: dateKey(akhir),
  }
}

function diffPersen(nilai, pembanding) {
  if (!pembanding) return nilai > 0 ? 100 : 0
  return Math.round(((nilai - pembanding) / pembanding) * 100)
}

function formatTanggalPendek(value) {
  if (!value) return "-"
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return String(value)
  return `${date.getDate()} ${NAMA_BULAN[date.getMonth()]}`
}

function waktuRelatif(value) {
  if (!value) return "-"
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return "-"
  const diffMs = Date.now() - date.getTime()
  const diffJam = Math.floor(diffMs / (1000 * 60 * 60))
  if (diffJam < 1) return "Baru saja"
  if (diffJam < 24) return `${diffJam} jam lalu`
  const diffHari = Math.floor(diffJam / 24)
  if (diffHari === 1) return "Kemarin"
  return `${diffHari} hari lalu`
}

function nominalPembayaran(row) {
  const nominal = Number(row.jumlah_bayar) || 0
  return row.status === "refund" ? -nominal : nominal
}

async function ambilKontrakIdsPemilik(pemilik_id) {
  const rows = await Kontrak.findAll({
    attributes: ["id"],
    include: [
      {
        model: Kamar,
        required: true,
        attributes: [],
        include: [
          {
            model: Kos,
            required: true,
            attributes: [],
            where: { pemilik_id, status: "aktif" },
          },
        ],
      },
    ],
    raw: true,
  })

  return rows.map((row) => row.id)
}

async function hitungPendapatan(tagihanIds, range) {
  if (!tagihanIds.length) return { total: 0, jumlah: 0 }

  const rows = await Pembayaran.findAll({
    where: {
      tagihan_id: { [Op.in]: tagihanIds },
      dibuat_pada: {
        [Op.between]: [
          `${range.tanggal_awal} 00:00:00`,
          `${range.tanggal_akhir} 23:59:59`,
        ],
      },
    },
    attributes: ["jumlah_bayar", "status"],
    raw: true,
  })

  return {
    total: rows.reduce((sum, row) => sum + nominalPembayaran(row), 0),
    jumlah: rows.length,
  }
}

async function trenPendapatan(tagihanIds, now) {
  const hasil = []
  for (let i = 5; i >= 0; i--) {
    const cursor = new Date(now.getFullYear(), now.getMonth() - i, 1)
    const range = monthRange(cursor)
    const pendapatan = await hitungPendapatan(tagihanIds, range)
    hasil.push({
      bulan: NAMA_BULAN[cursor.getMonth()],
      nilai: Math.round(pendapatan.total / 1000000),
      nominal: pendapatan.total,
    })
  }
  return hasil
}

function aktivitasPembayaran(row) {
  const tagihan = row.Tagihan || {}
  const kontrak = tagihan.Kontrak || {}
  const penyewa = kontrak.Penyewa || {}
  const status = row.status === "refund" ? "Refund pembayaran" : "Pembayaran masuk"
  return {
    judul: status,
    detail: `${penyewa.nama || "Penyewa"} - ${tagihan.kode_tagihan || "Tagihan"}`,
    waktu: waktuRelatif(row.dibuat_pada),
    ikon: "pembayaran",
    waktu_sort: row.dibuat_pada,
  }
}

function aktivitasKontrak(row) {
  const penyewa = row.Penyewa || {}
  const kamar = row.Kamar || {}
  const kos = kamar.kos || {}
  return {
    judul: "Kontrak baru",
    detail: `${penyewa.nama || "Penyewa"} - Kamar ${kamar.nomor || "-"}, ${kos.nama_kos || "Kos"}`,
    waktu: waktuRelatif(row.dibuat_pada),
    ikon: "kontrak",
    waktu_sort: row.dibuat_pada,
  }
}

function aktivitasTagihan(row) {
  const kontrak = row.Kontrak || {}
  const penyewa = kontrak.Penyewa || {}
  return {
    judul: "Tagihan terbit",
    detail: `${penyewa.nama || "Penyewa"} - ${row.kode_tagihan || "Tagihan"}`,
    waktu: waktuRelatif(row.dibuat_pada),
    ikon: "tagihan",
    waktu_sort: row.dibuat_pada,
  }
}

exports.ambil_ringkasan = async (pemilik_id) => {
  if (!pemilik_id) {
    throwError("pemilik tidak ditemukan", 401, "UNAUTHORIZED")
  }

  const now = new Date()
  const periodeIni = monthRange(now)
  const periodeLalu = monthRange(new Date(now.getFullYear(), now.getMonth() - 1, 1))

  const pemilik = await User.findOne({
    where: { id: pemilik_id },
    attributes: ["id", "nama"],
    raw: true,
  })

  const kosRows = await Kos.findAll({
    where: { pemilik_id, status: "aktif" },
    attributes: ["id", "nama_kos"],
    raw: true,
  })
  const kosIds = kosRows.map((kos) => kos.id)

  const kamarRows = kosIds.length
    ? await Kamar.findAll({
        where: { kos_id: { [Op.in]: kosIds }, status: "aktif" },
        attributes: ["id", "kos_id", "status_kondisi"],
        raw: true,
      })
    : []

  const kamarIds = kamarRows.map((kamar) => kamar.id)
  const kontrakRows = kamarIds.length
    ? await Kontrak.findAll({
        where: { kamar_id: { [Op.in]: kamarIds }, status: "aktif" },
        attributes: ["id", "penyewa_id", "kamar_id"],
        raw: true,
      })
    : []

  const kontrakIds = await ambilKontrakIdsPemilik(pemilik_id)
  const penyewaAktif = await Penyewa.count({
    where: { pemilik_id, status: "aktif" },
  })

  const tagihanRows = kontrakIds.length
    ? await Tagihan.findAll({
        where: {
          kontrak_id: { [Op.in]: kontrakIds },
          lifecycle: "issued",
          jatuh_tempo: {
            [Op.between]: [periodeIni.tanggal_awal, periodeIni.tanggal_akhir],
          },
        },
        attributes: [
          "id",
          "kode_tagihan",
          "kontrak_id",
          "jatuh_tempo",
          "total_tagihan",
          "status_pembayaran",
        ],
        raw: true,
      })
    : []

  const tagihanIds = kontrakIds.length
    ? (
        await Tagihan.findAll({
          where: { kontrak_id: { [Op.in]: kontrakIds }, lifecycle: "issued" },
          attributes: ["id"],
          raw: true,
        })
      ).map((row) => row.id)
    : []

  const pendapatanIni = await hitungPendapatan(tagihanIds, periodeIni)
  const pendapatanLalu = await hitungPendapatan(tagihanIds, periodeLalu)
  const trend = await trenPendapatan(tagihanIds, now)

  const totalKamar = kamarRows.length
  const kamarTerisi = kamarRows.filter((kamar) =>
    ["penuh", "sebagian"].includes(kamar.status_kondisi)
  ).length
  const okupansiPersen = totalKamar === 0 ? 0 : Math.round((kamarTerisi / totalKamar) * 100)

  const kontrakByKamar = {}
  for (const kontrak of kontrakRows) {
    kontrakByKamar[kontrak.kamar_id] = (kontrakByKamar[kontrak.kamar_id] || 0) + 1
  }

  const okupansiPerKos = kosRows.map((kos) => {
    const kamarKos = kamarRows.filter((kamar) => kamar.kos_id === kos.id)
    const terisi = kamarKos.filter((kamar) =>
      ["penuh", "sebagian"].includes(kamar.status_kondisi)
    ).length
    return {
      id: kos.id,
      nama: kos.nama_kos,
      terisi,
      total: kamarKos.length,
    }
  })

  const statusMap = {
    lunas: { label: "Lunas", jumlah: 0, status: "lunas" },
    sebagian: { label: "Sebagian", jumlah: 0, status: "sebagian" },
    belum_bayar: { label: "Belum bayar", jumlah: 0, status: "belum_bayar" },
    telat: { label: "Telat", jumlah: 0, status: "telat" },
  }
  for (const tagihan of tagihanRows) {
    const status = tagihan.status_pembayaran
    if (statusMap[status]) statusMap[status].jumlah += 1
  }

  const tagihanPerhatian = kontrakIds.length
    ? await Tagihan.findAll({
        where: {
          kontrak_id: { [Op.in]: kontrakIds },
          lifecycle: "issued",
          status_pembayaran: { [Op.in]: ["telat", "sebagian", "belum_bayar"] },
        },
        attributes: ["id", "jatuh_tempo", "total_tagihan", "status_pembayaran"],
        include: [
          {
            model: Kontrak,
            required: true,
            attributes: ["id"],
            include: [
              { model: Penyewa, required: true, attributes: ["nama"] },
              {
                model: Kamar,
                required: true,
                attributes: ["nomor"],
                include: [{ model: Kos, required: true, attributes: ["nama_kos"] }],
              },
            ],
          },
        ],
        order: [
          ["status_pembayaran", "DESC"],
          ["jatuh_tempo", "ASC"],
        ],
        limit: 5,
      })
    : []

  const perhatian = tagihanPerhatian.map((row) => {
    const plain = row.get({ plain: true })
    const kontrak = plain.Kontrak || {}
    const kamar = kontrak.Kamar || {}
    const kos = kamar.kos || {}
    return {
      penyewa: kontrak.Penyewa?.nama || "Penyewa",
      kos: kos.nama_kos || "Kos",
      jumlah: Number(plain.total_tagihan) || 0,
      status: plain.status_pembayaran,
      jatuh_tempo: formatTanggalPendek(plain.jatuh_tempo),
    }
  })

  const pembayaranAktivitas = tagihanIds.length
    ? await Pembayaran.findAll({
        where: { tagihan_id: { [Op.in]: tagihanIds } },
        attributes: ["jumlah_bayar", "status", "dibuat_pada"],
        include: [
          {
            model: Tagihan,
            required: true,
            attributes: ["kode_tagihan"],
            include: [
              {
                model: Kontrak,
                required: true,
                attributes: ["id"],
                include: [{ model: Penyewa, required: true, attributes: ["nama"] }],
              },
            ],
          },
        ],
        order: [["dibuat_pada", "DESC"]],
        limit: 5,
      })
    : []

  const kontrakAktivitas = kamarIds.length
    ? await Kontrak.findAll({
        where: { kamar_id: { [Op.in]: kamarIds } },
        attributes: ["dibuat_pada"],
        include: [
          { model: Penyewa, required: true, attributes: ["nama"] },
          {
            model: Kamar,
            required: true,
            attributes: ["nomor"],
            include: [{ model: Kos, required: true, attributes: ["nama_kos"] }],
          },
        ],
        order: [["dibuat_pada", "DESC"]],
        limit: 5,
      })
    : []

  const tagihanAktivitas = kontrakIds.length
    ? await Tagihan.findAll({
        where: { kontrak_id: { [Op.in]: kontrakIds }, lifecycle: "issued" },
        attributes: ["kode_tagihan", "dibuat_pada"],
        include: [
          {
            model: Kontrak,
            required: true,
            attributes: ["id"],
            include: [{ model: Penyewa, required: true, attributes: ["nama"] }],
          },
        ],
        order: [["dibuat_pada", "DESC"]],
        limit: 5,
      })
    : []

  const aktivitas = [
    ...pembayaranAktivitas.map((row) => aktivitasPembayaran(row.get({ plain: true }))),
    ...kontrakAktivitas.map((row) => aktivitasKontrak(row.get({ plain: true }))),
    ...tagihanAktivitas.map((row) => aktivitasTagihan(row.get({ plain: true }))),
  ]
    .sort((a, b) => new Date(b.waktu_sort) - new Date(a.waktu_sort))
    .slice(0, 5)
    .map(({ waktu_sort, ...row }) => row)

  return {
    pemilik: {
      nama: pemilik?.nama || "Pemilik",
    },
    periode: periodeIni,
    ringkasan: {
      jumlah_kos: kosRows.length,
      total_kamar: totalKamar,
      kamar_terisi: kamarTerisi,
      penyewa_aktif: penyewaAktif,
      kontrak_aktif: kontrakRows.length,
      okupansi_persen: okupansiPersen,
      tagihan_belum_lunas: tagihanRows.filter((row) => row.status_pembayaran !== "lunas").length,
      tagihan_telat: statusMap.telat.jumlah,
      pembayaran_bulan_ini: pendapatanIni.jumlah,
    },
    pendapatan: {
      bulan_ini: pendapatanIni.total,
      bulan_lalu: pendapatanLalu.total,
      delta_persen: diffPersen(pendapatanIni.total, pendapatanLalu.total),
      trend,
    },
    okupansi: {
      per_kos: okupansiPerKos,
    },
    tagihan: {
      status: Object.values(statusMap),
      perhatian,
    },
    aktivitas,
  }
}
