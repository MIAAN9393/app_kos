const { DataTypes } = require("sequelize");
const sequelize = require("../config/database");

const SubscriptionPayment = sequelize.define(
  "SubscriptionPayment",
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

    order_id: {
      type: DataTypes.STRING(100),
      allowNull: false,
      unique: true,
    },

    paket: {
      type: DataTypes.STRING(100),
      allowNull: false,
    },

    jumlah: {
      type: DataTypes.BIGINT,
      allowNull: false,
    },

    status: {
      type: DataTypes.ENUM(
        "pending",
        "settlement",
        "capture",
        "expire",
        "cancel",
        "deny",
        "failure"
      ),
      defaultValue: "pending",
    },

    snap_token: {
      type: DataTypes.TEXT,
      allowNull: true,
    },

    redirect_url: {
      type: DataTypes.TEXT,
      allowNull: true,
    },

    payment_type: {
      type: DataTypes.STRING(50),
      allowNull: true,
    },

    fraud_status: {
      type: DataTypes.STRING(50),
      allowNull: true,
    },

    raw_response: {
      type: DataTypes.JSON,
      allowNull: true,
    },

    paid_at: {
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
    tableName: "pembayaran_langganan",
    timestamps: true,
    createdAt: "created_at",
    updatedAt: "updated_at",
    indexes: [
      {
        name: "idx_pembayaran_langganan_user",
        fields: ["user_id"],
      },
      {
        name: "idx_pembayaran_langganan_order",
        unique: true,
        fields: ["order_id"],
      },
      {
        name: "idx_pembayaran_langganan_status",
        fields: ["status"],
      },
    ],
  }
);

module.exports = SubscriptionPayment;
