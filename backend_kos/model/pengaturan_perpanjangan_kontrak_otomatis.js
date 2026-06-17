const { DataTypes } = require("sequelize")
const sequelize = require("../config/database")

const PengaturanPerpanjanganKontrakOtomatis = sequelize.define(
  "PengaturanPerpanjanganKontrakOtomatis",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },

    kontrak_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      field: "kontrak_awal_id",
    },

    jenis_perpanjangan: {
      type: DataTypes.ENUM("tahunan", "bulanan", "mingguan", "harian"),
      defaultValue: "bulanan",
    },

    jumlah_periode_perpanjangan: {
      type: DataTypes.INTEGER,
      defaultValue: 1,
    },

    hari_sebelum_berakhir: {
      type: DataTypes.INTEGER,
      defaultValue: 30,
    },

    harga_perpanjangan: {
      type: DataTypes.BIGINT,
      allowNull: true,
    },

    tanggal_proses_berikutnya: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },

    kontrak_terakhir_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    status: {
      type: DataTypes.ENUM("aktif", "nonaktif"),
      defaultValue: "aktif",
    },

    dibuat_pada: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },

    diperbarui_pada: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  },
  {
    tableName: "pengaturan_perpanjangan_kontrak_otomatis",
    timestamps: true,
    createdAt: "dibuat_pada",
    updatedAt: "diperbarui_pada",
  }
)

module.exports = PengaturanPerpanjanganKontrakOtomatis
