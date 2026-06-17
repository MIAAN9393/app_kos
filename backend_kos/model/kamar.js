const { DataTypes } = require("sequelize");
const sequelize = require("../config/database");

const Kamar = sequelize.define("kamar",{
    id:{
        type:DataTypes.INTEGER,
        primaryKey:true,
        autoIncrement:true
    },
    kos_id:{
        type:DataTypes.INTEGER
    },
    nomor:{
        type:DataTypes.STRING(20)
    },
    harga:{
        type:DataTypes.BIGINT
    },
    kapasitas:{
        type:DataTypes.INTEGER.UNSIGNED
    },
    status_kondisi:{
        type:DataTypes.ENUM('kosong','sebagian','penuh'),
        defaultValue:"kosong"
    },
    status:{
        type:DataTypes.ENUM('aktif','nonaktif'),
        defaultValue:"aktif"
    },
    fasilitas:{
        type:DataTypes.JSON,
        allowNull:true
    }
},{
    tableName:"Kamar",
    timestamps:false
});

module.exports = Kamar;