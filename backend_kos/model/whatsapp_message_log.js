const { DataTypes } = require("sequelize")
const sequelize = require("../config/database")

const WhatsAppMessageLog = sequelize.define(
  "WhatsAppMessageLog",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },

    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    tagihan_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    kontrak_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    penyewa_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    no_tujuan: {
      type: DataTypes.STRING(30),
      allowNull: false,
    },

    tipe: {
      type: DataTypes.ENUM("test", "invoice", "kontrak", "reminder"),
      allowNull: false,
    },

    status: {
      type: DataTypes.ENUM("pending", "sent", "failed"),
      defaultValue: "pending",
    },

    wa_message_id: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },

    error_message: {
      type: DataTypes.TEXT,
      allowNull: true,
    },

    created_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },

    updated_at: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW,
    },
  },
  {
    tableName: "whatsapp_message_logs",
    timestamps: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
  }
)

module.exports = WhatsAppMessageLog
