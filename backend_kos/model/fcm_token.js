const { DataTypes } = require("sequelize")
const sequelize = require("../config/database")

const FcmToken = sequelize.define(
  "FcmToken",
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
    token: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    platform: {
      type: DataTypes.ENUM("android", "ios", "web"),
      defaultValue: "android",
    },
    status: {
      type: DataTypes.ENUM("aktif", "nonaktif"),
      defaultValue: "aktif",
    },
  },
  {
    tableName: "fcm_tokens",
    timestamps: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
  }
)

module.exports = FcmToken
