require("dotenv").config()

const sequelize = require("../config/database")
require("../model/index")

const User = require("../model/user")
const Kos = require("../model/kos")
const Kamar = require("../model/kamar")
const Penyewa = require("../model/penyewa")
const Kontrak = require("../model/kontrak")
const Tagihan = require("../model/tagihan")
const TagihanItem = require("../model/tagihan_item")
const PengaturanTagihanOtomatis = require("../model/pengaturan_tagihan_otomatis")
const PengaturanPerpanjanganKontrakOtomatis = require("../model/pengaturan_perpanjangan_kontrak_otomatis")
const { generateTagihanOtomatis } = require("../services/pengaturan_tagihan_otomatis_service")
const {
  generatePerpanjanganKontrakOtomatis,
} = require("../services/pengaturan_perpanjangan_kontrak_otomatis_service")
const {
  ambil_tanggal_timezone,
  tambah_hari,
  kurang_hari,
} = require("../utils/waktu")

const TEST_EMAIL = "codex-auto-cron-test@example.com"

const pick = (row, fields) => {
  if (!row) return null
  const plain = row.get ? row.get({ plain: true }) : row
  return fields.reduce((out, field) => {
    out[field] = plain[field]
    return out
  }, {})
}

const cekDuplikasiTagihanSewa = async () => {
  const [duplicates] = await sequelize.query(`
    SELECT
      t.kontrak_id,
      t.periode_awal,
      t.periode_akhir,
      COUNT(DISTINCT t.id) AS jumlah,
      GROUP_CONCAT(DISTINCT t.id ORDER BY t.id) AS tagihan_ids
    FROM tagihan t
    INNER JOIN tagihan_item ti ON ti.tagihan_id = t.id AND ti.tipe = 'sewa'
    WHERE t.lifecycle <> 'cancelled'
    GROUP BY t.kontrak_id, t.periode_awal, t.periode_akhir
    HAVING COUNT(DISTINCT t.id) > 1
    LIMIT 10
  `)

  if (duplicates.length > 0) {
    return {
      status: "warning",
      alasan: "Ada lebih dari satu tagihan aktif dengan item sewa untuk kontrak/periode yang sama.",
      duplicates,
    }
  }

  return { status: "ok" }
}

const buatDataAwal = async () => {
  const hari_ini = ambil_tanggal_timezone()
  const kode = Date.now()

  const t = await sequelize.transaction()

  try {
    const [user] = await User.findOrCreate({
      where: { email: TEST_EMAIL },
      defaults: {
        nama: "Codex Auto Cron Test",
        email: TEST_EMAIL,
        password: null,
        role: "pemilik",
        status: "aktif",
      },
      transaction: t,
    })

    const kos = await Kos.create(
      {
        pemilik_id: user.id,
        nama_kos: `Kos Auto Cron Test ${kode}`,
        alamat: "Alamat testing cron otomatis",
        deskripsi: "Data dibuat oleh scripts/manual_cron_otomatis_test.js",
        status: "aktif",
      },
      { transaction: t }
    )

    const kamarTagihan = await Kamar.create(
      {
        kos_id: kos.id,
        nomor: `AUTO-TGH-${kode}`,
        harga: 750000,
        kapasitas: 1,
        status_kondisi: "kosong",
        status: "aktif",
        fasilitas: null,
      },
      { transaction: t }
    )

    const kamarPerpanjangan = await Kamar.create(
      {
        kos_id: kos.id,
        nomor: `AUTO-KTR-${kode}`,
        harga: 800000,
        kapasitas: 1,
        status_kondisi: "kosong",
        status: "aktif",
        fasilitas: null,
      },
      { transaction: t }
    )

    const penyewaTagihan = await Penyewa.create(
      {
        pemilik_id: user.id,
        nama: `Penyewa Tagihan Otomatis ${kode}`,
        no_telpon: "081234567890",
        email: `tagihan-${kode}@example.com`,
        status: "aktif",
      },
      { transaction: t }
    )

    const penyewaPerpanjangan = await Penyewa.create(
      {
        pemilik_id: user.id,
        nama: `Penyewa Perpanjangan Otomatis ${kode}`,
        no_telpon: "081234567891",
        email: `perpanjangan-${kode}@example.com`,
        status: "aktif",
      },
      { transaction: t }
    )

    const kontrakTagihan = await Kontrak.create(
      {
        kode_kontrak: `TEST-TGH-${kode}`,
        penyewa_id: penyewaTagihan.id,
        kamar_id: kamarTagihan.id,
        tanggal_mulai: hari_ini,
        tanggal_selesai: tambah_hari(hari_ini, 90),
        harga_sewa: 750000,
        siklus: "bulanan",
        status: "aktif",
      },
      { transaction: t }
    )

    const kontrakPerpanjangan = await Kontrak.create(
      {
        kode_kontrak: `TEST-KTR-${kode}`,
        penyewa_id: penyewaPerpanjangan.id,
        kamar_id: kamarPerpanjangan.id,
        tanggal_mulai: kurang_hari(hari_ini, 29),
        tanggal_selesai: hari_ini,
        harga_sewa: 800000,
        siklus: "bulanan",
        status: "aktif",
      },
      { transaction: t }
    )

    const pengaturanTagihan = await PengaturanTagihanOtomatis.create(
      {
        kontrak_id: kontrakTagihan.id,
        hari_sebelum_periode_mulai: 0,
        jatuh_tempo_setelah_periode_mulai_hari: 3,
        tanggal_proses_berikutnya: hari_ini,
        status: "aktif",
      },
      { transaction: t }
    )

    const pengaturanTagihanUntukPerpanjangan = await PengaturanTagihanOtomatis.create(
      {
        kontrak_id: kontrakPerpanjangan.id,
        hari_sebelum_periode_mulai: 2,
        jatuh_tempo_setelah_periode_mulai_hari: 5,
        tanggal_proses_berikutnya: tambah_hari(hari_ini, 30),
        status: "aktif",
      },
      { transaction: t }
    )

    const pengaturanPerpanjangan = await PengaturanPerpanjanganKontrakOtomatis.create(
      {
        kontrak_id: kontrakPerpanjangan.id,
        jenis_perpanjangan: "bulanan",
        jumlah_periode_perpanjangan: 1,
        hari_sebelum_berakhir: 0,
        harga_perpanjangan: 900000,
        tanggal_proses_berikutnya: hari_ini,
        status: "aktif",
      },
      { transaction: t }
    )

    await t.commit()

    return {
      hari_ini,
      user: pick(user, ["id", "email"]),
      kos: pick(kos, ["id", "nama_kos"]),
      kontrak_tagihan: pick(kontrakTagihan, [
        "id",
        "kode_kontrak",
        "tanggal_mulai",
        "tanggal_selesai",
        "harga_sewa",
        "siklus",
        "status",
      ]),
      pengaturan_tagihan: pick(pengaturanTagihan, [
        "id",
        "kontrak_id",
        "tanggal_proses_berikutnya",
        "status",
      ]),
      kontrak_perpanjangan: pick(kontrakPerpanjangan, [
        "id",
        "kode_kontrak",
        "tanggal_mulai",
        "tanggal_selesai",
        "harga_sewa",
        "siklus",
        "status",
      ]),
      pengaturan_tagihan_untuk_perpanjangan: pick(
        pengaturanTagihanUntukPerpanjangan,
        [
          "id",
          "kontrak_id",
          "hari_sebelum_periode_mulai",
          "jatuh_tempo_setelah_periode_mulai_hari",
          "status",
        ]
      ),
      pengaturan_perpanjangan: pick(pengaturanPerpanjangan, [
        "id",
        "kontrak_id",
        "jenis_perpanjangan",
        "jumlah_periode_perpanjangan",
        "hari_sebelum_berakhir",
        "harga_perpanjangan",
        "tanggal_proses_berikutnya",
        "status",
      ]),
    }
  } catch (error) {
    await t.rollback()
    throw error
  }
}

const verifikasiTagihanTerbaru = async () => {
  const pengaturan = await PengaturanTagihanOtomatis.findOne({
    where: { tagihan_terakhir_id: { [sequelize.Sequelize.Op.ne]: null } },
    order: [["id", "DESC"]],
  })

  if (!pengaturan) return null

  const tagihan = await Tagihan.findByPk(pengaturan.tagihan_terakhir_id)
  const items = await TagihanItem.findAll({
    where: { tagihan_id: pengaturan.tagihan_terakhir_id },
    order: [["id", "ASC"]],
  })
  const kontrak = await Kontrak.findByPk(pengaturan.kontrak_id)

  return {
    pengaturan: pick(pengaturan, [
      "id",
      "kontrak_id",
      "periode_awal_terakhir_dibuat",
      "periode_akhir_terakhir_dibuat",
      "tagihan_terakhir_id",
      "tanggal_proses_berikutnya",
      "status",
    ]),
    kontrak: pick(kontrak, ["id", "harga_sewa"]),
    tagihan: pick(tagihan, [
      "id",
      "kode_tagihan",
      "kontrak_id",
      "periode_awal",
      "periode_akhir",
      "jatuh_tempo",
      "total_tagihan",
      "lifecycle",
      "status_pembayaran",
    ]),
    items: items.map((item) =>
      pick(item, ["id", "tagihan_id", "tipe", "nama_item", "nominal", "event_date"])
    ),
    checks: {
      tagihan_dibuat: Boolean(tagihan),
      item_sewa_dibuat: items.some((item) => item.tipe === "sewa"),
      total_sesuai_harga_kontrak:
        tagihan && kontrak
          ? Number(tagihan.total_tagihan) === Number(kontrak.harga_sewa)
          : false,
      setting_terupdate: Boolean(
        pengaturan.periode_awal_terakhir_dibuat &&
          pengaturan.periode_akhir_terakhir_dibuat &&
          pengaturan.tagihan_terakhir_id &&
          pengaturan.tanggal_proses_berikutnya
      ),
    },
  }
}

const verifikasiPerpanjanganTerbaru = async () => {
  const pengaturanLama = await PengaturanPerpanjanganKontrakOtomatis.findOne({
    where: {
      status: "nonaktif",
      kontrak_terakhir_id: { [sequelize.Sequelize.Op.ne]: null },
    },
    order: [["id", "DESC"]],
  })

  if (!pengaturanLama) return null

  const kontrakBaru = await Kontrak.findByPk(pengaturanLama.kontrak_terakhir_id)
  const settingBaru = await PengaturanPerpanjanganKontrakOtomatis.findOne({
    where: { kontrak_id: pengaturanLama.kontrak_terakhir_id },
  })
  const settingTagihanCopy = await PengaturanTagihanOtomatis.findOne({
    where: { kontrak_id: pengaturanLama.kontrak_terakhir_id },
  })

  return {
    pengaturan_lama: pick(pengaturanLama, [
      "id",
      "kontrak_id",
      "harga_perpanjangan",
      "kontrak_terakhir_id",
      "status",
    ]),
    kontrak_baru: pick(kontrakBaru, [
      "id",
      "kode_kontrak",
      "tanggal_mulai",
      "tanggal_selesai",
      "harga_sewa",
      "siklus",
      "status",
    ]),
    pengaturan_perpanjangan_baru: pick(settingBaru, [
      "id",
      "kontrak_id",
      "jenis_perpanjangan",
      "jumlah_periode_perpanjangan",
      "hari_sebelum_berakhir",
      "harga_perpanjangan",
      "tanggal_proses_berikutnya",
      "status",
    ]),
    pengaturan_tagihan_copy: pick(settingTagihanCopy, [
      "id",
      "kontrak_id",
      "hari_sebelum_periode_mulai",
      "jatuh_tempo_setelah_periode_mulai_hari",
      "tanggal_proses_berikutnya",
      "periode_awal_terakhir_dibuat",
      "periode_akhir_terakhir_dibuat",
      "tagihan_terakhir_id",
      "status",
    ]),
    checks: {
      kontrak_pending: kontrakBaru?.status === "pending",
      harga_pakai_harga_perpanjangan:
        Number(kontrakBaru?.harga_sewa) === Number(pengaturanLama.harga_perpanjangan),
      setting_lama_nonaktif: pengaturanLama.status === "nonaktif",
      kontrak_terakhir_terisi: Boolean(pengaturanLama.kontrak_terakhir_id),
      setting_baru_dibuat: Boolean(settingBaru),
      setting_tagihan_dicopy: Boolean(settingTagihanCopy),
    },
  }
}

const main = async () => {
  const mode = process.argv[2] || "all"
  await sequelize.authenticate()

  const output = { mode }

  if (mode === "cek-duplikasi-sewa" || mode === "all") {
    output.cek_duplikasi_sewa = await cekDuplikasiTagihanSewa()
  }

  if (mode === "seed" || mode === "all") {
    output.data_awal = await buatDataAwal()
  }

  if (mode === "tagihan" || mode === "all") {
    output.generate_tagihan = await generateTagihanOtomatis()
    output.verifikasi_tagihan = await verifikasiTagihanTerbaru()
  }

  if (mode === "perpanjangan" || mode === "all") {
    output.generate_perpanjangan = await generatePerpanjanganKontrakOtomatis()
    output.verifikasi_perpanjangan = await verifikasiPerpanjanganTerbaru()
  }

  console.log(JSON.stringify(output, null, 2))
  await sequelize.close()
}

main().catch(async (error) => {
  console.error(error)
  await sequelize.close()
  process.exit(1)
})
