const { DataTypes } = require("sequelize");
const sequelize = require("../config/database");

const UserSubscription = sequelize.define(
  "UserSubscription",
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

    paket: {
      type: DataTypes.ENUM("free", "starter", "pro"),
      allowNull: false,
      defaultValue: "free",
    },

    status: {
      type: DataTypes.ENUM("active", "expired", "cancelled"),
      allowNull: false,
      defaultValue: "active",
    },

    source_payment_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },

    started_at: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },

    expired_at: {
      type: DataTypes.DATE,
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
    tableName: "user_subscriptions",
    timestamps: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
    indexes: [
      {
        name: "idx_user_subscriptions_user_status",
        fields: ["user_id", "status"],
      },
      {
        name: "idx_user_subscriptions_expired_at",
        fields: ["expired_at"],
      },
    ],
  }
);

module.exports = UserSubscription;
