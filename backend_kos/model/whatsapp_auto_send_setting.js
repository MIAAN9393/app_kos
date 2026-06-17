const { DataTypes } = require("sequelize")
const sequelize = require("../config/database")

const WhatsAppAutoSendSetting = sequelize.define(
  "WhatsAppAutoSendSetting",
  {
    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },

    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      unique: true,
    },

    auto_send_tagihan_on_create: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },

    auto_send_tagihan_from_cron: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },

    auto_send_tagihan_reminder_before_due: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },

    auto_send_tagihan_reminder_overdue: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },

    auto_send_penyewa_contract_on_create: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },

    auto_send_penyewa_contract_from_cron: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },

    auto_send_penyewa_reminder_before_contract_end: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  },
  {
    tableName: "whatsapp_auto_send_settings",
    timestamps: false,
  }
)

module.exports = WhatsAppAutoSendSetting
