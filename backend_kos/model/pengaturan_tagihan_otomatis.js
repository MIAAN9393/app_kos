const { DataTypes } = require("sequelize")
const sequelize = require("../config/database")

const PengaturanTagihanOtomatis = sequelize.define(
  "PengaturanTagihanOtomatis",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },

    kontrak_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    hari_sebelum_periode_mulai: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },

    jatuh_tempo_setelah_periode_mulai_hari: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },

    tanggal_proses_berikutnya: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },

    periode_awal_terakhir_dibuat: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },

    periode_akhir_terakhir_dibuat: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },

    tagihan_terakhir_id: {
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
    tableName: "pengaturan_tagihan_otomatis",
    timestamps: true,
    createdAt: "dibuat_pada",
    updatedAt: "diperbarui_pada",
  }
)

module.exports = PengaturanTagihanOtomatis
