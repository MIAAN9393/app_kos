const { DataTypes } = require("sequelize");
const sequelize = require("../config/database");

const TagihanItem = sequelize.define(
  "TagihanItem",
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

    tipe: {
      type: DataTypes.ENUM(
        "sewa",
        "insiden",
        "denda",
        "diskon"
      ),
      allowNull: false,
    },

    nama_item: {
      type: DataTypes.STRING(100),
      allowNull: false,
    },

    deskripsi: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },

    nominal: {
      type: DataTypes.BIGINT,
      allowNull: false,
    },

    event_date: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },

    dibuat_pada: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  },
  {
    tableName: "tagihan_item",
    timestamps: false,
    indexes: [
      {
        name: "idx_item_tagihan",
        fields: ["tagihan_id"],
      },
      {
        name: "idx_item_tipe",
        fields: ["tipe"],
      },
    ],
  }
);

module.exports = TagihanItem;