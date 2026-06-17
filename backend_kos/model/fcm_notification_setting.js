const { DataTypes } = require("sequelize")
const sequelize = require("../config/database")

const FcmNotificationSetting = sequelize.define(
  "FcmNotificationSetting",
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
    notif_tagihan_jatuh_tempo: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    notif_tagihan_telat: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    notif_tagihan_otomatis: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    notif_kontrak_akan_berakhir: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    notif_kontrak_selesai: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    notif_perpanjangan_otomatis: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
  },
  {
    tableName: "fcm_notification_settings",
    timestamps: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
  }
)

module.exports = FcmNotificationSetting
