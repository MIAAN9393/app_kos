const { DataTypes } = require("sequelize");
const sequelize = require("../config/database");

const Kos = sequelize.define("kos",{
    
    id:{
        type:DataTypes.INTEGER,
        primaryKey:true,
        autoIncrement:true
    },

    pemilik_id:{
        type:DataTypes.INTEGER,
        allowNull:false
    },

    nama_kos:{
        type:DataTypes.STRING,
        allowNull:false
    },

    alamat:{
        type:DataTypes.TEXT
    },

    deskripsi:{
        type:DataTypes.TEXT
    },

    status:{
        type:DataTypes.ENUM("aktif","nonaktif"),
        defaultValue:"aktif"
    }

},{
    tableName:"kos",
    timestamps:false
})

module.exports = Kos
