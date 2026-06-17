const { DataTypes } = require("sequelize");
const sequelize = require("../config/database");

  const Tagihan = sequelize.define(
    "Tagihan",
    {
      id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true,
      },

      kode_tagihan: {
        type: DataTypes.STRING(50),
        unique: true,
      },

      kontrak_id: {
        type: DataTypes.INTEGER,
        allowNull: false,
      },

      periode_awal: {
        type: DataTypes.DATEONLY,
        allowNull: false,
      },

      periode_akhir: {
        type: DataTypes.DATEONLY,
        allowNull: false,
      },

      jatuh_tempo: {
        type: DataTypes.DATEONLY,
        allowNull: false,
      },

      total_tagihan: {
        type: DataTypes.BIGINT,
        allowNull: false,
        defaultValue: 0,
      },

      lifecycle: {
        type: DataTypes.ENUM(
          "draft",
          "issued",
          "cancelled"
        ),
        defaultValue: "draft",
      },

      status_pembayaran: {
        type: DataTypes.ENUM(
          "belum_bayar",
          "sebagian",
          "lunas",
          "telat"
        ),
        defaultValue: "belum_bayar",
      },

      catatan: {
        type: DataTypes.TEXT,
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
      tableName: "tagihan",
      timestamps: true,

      createdAt: "dibuat_pada",
      updatedAt: "diperbarui_pada",
    }
  );

  module.exports = Tagihan;


