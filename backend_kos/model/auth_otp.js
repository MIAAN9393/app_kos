const { DataTypes } = require("sequelize")
const sequelize = require("../config/database")

const AuthOtp = sequelize.define(
  "AuthOtp",
  {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },

    user_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    email: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },

    no_telpon: {
      type: DataTypes.STRING(20),
      allowNull: true,
    },

    channel: {
      type: DataTypes.ENUM("email", "phone"),
      defaultValue: "email",
    },

    purpose: {
      type: DataTypes.ENUM("email_verification", "phone_verification", "password_reset"),
      allowNull: false,
    },

    code_hash: {
      type: DataTypes.STRING(64),
      allowNull: false,
    },

    expires_at: {
      type: DataTypes.DATE,
      allowNull: false,
    },

    used_at: {
      type: DataTypes.DATE,
      allowNull: true,
    },

    attempt_count: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
  },
  {
    tableName: "auth_otps",
    timestamps: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
  }
)

module.exports = AuthOtp
