const { DataTypes } = require("sequelize");
const sequelize = require("../config/database"); // sesuaikan dengan path koneksi kamu

const Penyewa = sequelize.define("Penyewa", {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },

  pemilik_id: {
    type: DataTypes.INTEGER,
    allowNull: false
  },

  nama: {
    type: DataTypes.STRING(100),
    allowNull: false
  },

  tanggal_lahir: {
    type: DataTypes.DATEONLY,
    allowNull: true
  },

  jenis_kelamin: {
    type: DataTypes.ENUM("pria", "wanita"),
    allowNull: true
  },

  status_hubungan: {
    type: DataTypes.ENUM("jomblo", "pacaran", "menikah", "duda", "janda"),
    allowNull: true
  },

  no_telpon: {
    type: DataTypes.STRING(20),
    allowNull: true
  },

  email: {
    type: DataTypes.STRING(100),
    allowNull: true,
  },

  status: {
    type: DataTypes.ENUM("aktif", "nonaktif"),
    defaultValue: "aktif"
  },

  dibuat_pada: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }

}, {
  tableName: "penyewa",
  timestamps: false
});

module.exports = Penyewa;
