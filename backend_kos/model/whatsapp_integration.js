const { DataTypes } = require("sequelize")
const sequelize = require("../config/database")

const WhatsAppIntegration = sequelize.define(
  "WhatsAppIntegration",
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

    phone_number_id: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },

    access_token: {
      type: DataTypes.TEXT,
      allowNull: true,
    },

    status: {
      type: DataTypes.ENUM("connected", "disconnected"),
      defaultValue: "disconnected",
    },
  },
  {
    tableName: "whatsapp_integrations",
    timestamps: false,
  }
)

module.exports = WhatsAppIntegration
