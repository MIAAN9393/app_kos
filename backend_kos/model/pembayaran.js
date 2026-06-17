const { DataTypes } = require("sequelize");
const sequelize = require("../config/database");

const Pembayaran = sequelize.define(
  "Pembayaran",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },

    tagihan_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    jumlah_bayar: {
      type: DataTypes.BIGINT,
      allowNull: false,
    },

    status: {
      type: DataTypes.ENUM("valid", "refund"),
      defaultValue: "valid",
    },

    pembayaran_ref_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    dibuat_pada: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },

    dibatalkan_pada: {
      type: DataTypes.DATE,
      allowNull: true,
    },
  },
  {
    tableName: "pembayaran",
    timestamps: false,
    indexes: [
      {
        name: "idx_pembayaran_tagihan",
        fields: ["tagihan_id"],
      },
      {
        name: "idx_pembayaran_ref",
        fields: ["pembayaran_ref_id"],
      },
      {
        name: "idx_status_ref",
        fields: ["status", "pembayaran_ref_id"],
      },
    ],
  }
);

module.exports = Pembayaran;