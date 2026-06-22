const PLANS = {
  free: {
    paket: "free",
    rank: 0,
    limits: {
      kos: 1,
      kamar: 5,
      penyewa_aktif: 5,
    },
    features: {
      dashboard: "dasar",
      laporan_keuangan: "bulan_ini",
      export_pdf: "terbatas",
      tagihan_otomatis: false,
      perpanjangan_otomatis: false,
      whatsapp_deep_link: true,
    },
  },
  starter: {
    paket: "starter",
    rank: 1,
    harga: 29000,
    limits: {
      kos: 3,
      kamar: 30,
      penyewa_aktif: 30,
    },
    features: {
      dashboard: "lengkap",
      laporan_keuangan: "rentang_bulan",
      export_pdf: true,
      tagihan_otomatis: true,
      perpanjangan_otomatis: true,
      whatsapp_deep_link: true,
    },
  },
  pro: {
    paket: "pro",
    rank: 2,
    harga: 49000,
    limits: {
      kos: null,
      kamar: null,
      penyewa_aktif: null,
    },
    features: {
      dashboard: "lengkap",
      laporan_keuangan: "rentang_bulan",
      export_pdf: true,
      tagihan_otomatis: true,
      perpanjangan_otomatis: true,
      whatsapp_deep_link: true,
    },
  },
};

function getPlan(paket = "free") {
  return PLANS[paket] || PLANS.free;
}

module.exports = {
  PLANS,
  getPlan,
};
