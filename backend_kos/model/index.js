
const User = require("./user")
const AuthOtp = require("./auth_otp")
const Kos = require("./kos")
const Kamar = require("./kamar")
const Penyewa = require("./penyewa")
const Kontrak = require("./kontrak")
const Tagihan = require("./tagihan")
const TagihanItem = require("./tagihan_item")
const Pembayaran = require("./pembayaran")
const WhatsAppIntegration = require("./whatsapp_integration")
const WhatsAppAutoSendSetting = require("./whatsapp_auto_send_setting")
const WhatsAppMessageLog = require("./whatsapp_message_log")
const PengaturanTagihanOtomatis = require("./pengaturan_tagihan_otomatis")
const PengaturanPerpanjanganKontrakOtomatis = require("./pengaturan_perpanjangan_kontrak_otomatis")
const FcmToken = require("./fcm_token")
const FcmNotificationSetting = require("./fcm_notification_setting")

User.hasMany(Kos,{
    foreignKey:"pemilik_id"
})
Kos.belongsTo(User,{
    foreignKey:"pemilik_id"
})

User.hasMany(AuthOtp,{
    foreignKey:"user_id"
})
AuthOtp.belongsTo(User,{
    foreignKey:"user_id"
})

Kos.hasMany(Kamar,{
    foreignKey:"kos_id"
})
Kamar.belongsTo(Kos,{
    foreignKey:"kos_id"
})

User.hasMany(Penyewa,{
    foreignKey:"pemilik_id"
})
Penyewa.belongsTo(User,{
    foreignKey:"pemilik_id"
})

Penyewa.hasMany(Kontrak,{
    foreignKey:"penyewa_id"
})
Kontrak.belongsTo(Penyewa,{
    foreignKey:"penyewa_id"
})

Kamar.hasMany(Kontrak,{
    foreignKey:"kamar_id"
})
Kontrak.belongsTo(Kamar,{
    foreignKey:"kamar_id"
})

Kontrak.hasMany(Tagihan,{
    foreignKey:"kontrak_id"
})
Tagihan.belongsTo(Kontrak,{
    foreignKey:"kontrak_id"
})

Tagihan.hasMany(TagihanItem,{
    foreignKey:"tagihan_id"
})
TagihanItem.belongsTo(Tagihan,{
    foreignKey:"tagihan_id"
})

Tagihan.hasMany(Pembayaran,{
    foreignKey:"tagihan_id"
})
Pembayaran.belongsTo(Tagihan,{
    foreignKey:"tagihan_id"
})

User.hasOne(WhatsAppIntegration,{
    foreignKey:"user_id"
})
WhatsAppIntegration.belongsTo(User,{
    foreignKey:"user_id"
})

User.hasOne(WhatsAppAutoSendSetting,{
    foreignKey:"user_id"
})
WhatsAppAutoSendSetting.belongsTo(User,{
    foreignKey:"user_id"
})

User.hasMany(WhatsAppMessageLog,{
    foreignKey:"user_id"
})
WhatsAppMessageLog.belongsTo(User,{
    foreignKey:"user_id"
})

User.hasMany(FcmToken,{
    foreignKey:"user_id"
})
FcmToken.belongsTo(User,{
    foreignKey:"user_id"
})

User.hasOne(FcmNotificationSetting,{
    foreignKey:"user_id"
})
FcmNotificationSetting.belongsTo(User,{
    foreignKey:"user_id"
})

Tagihan.hasMany(WhatsAppMessageLog,{
    foreignKey:"tagihan_id"
})
WhatsAppMessageLog.belongsTo(Tagihan,{
    foreignKey:"tagihan_id"
})

Kontrak.hasMany(WhatsAppMessageLog,{
    foreignKey:"kontrak_id"
})
WhatsAppMessageLog.belongsTo(Kontrak,{
    foreignKey:"kontrak_id"
})

Penyewa.hasMany(WhatsAppMessageLog,{
    foreignKey:"penyewa_id"
})
WhatsAppMessageLog.belongsTo(Penyewa,{
    foreignKey:"penyewa_id"
})

Kontrak.hasOne(PengaturanTagihanOtomatis,{
    foreignKey:"kontrak_id"
})
PengaturanTagihanOtomatis.belongsTo(Kontrak,{
    foreignKey:"kontrak_id"
})

Tagihan.hasMany(PengaturanTagihanOtomatis,{
    foreignKey:"tagihan_terakhir_id"
})
PengaturanTagihanOtomatis.belongsTo(Tagihan,{
    as:"tagihanTerakhir",
    foreignKey:"tagihan_terakhir_id"
})

Kontrak.hasOne(PengaturanPerpanjanganKontrakOtomatis,{
    as:"pengaturanPerpanjanganAwal",
    foreignKey:{
        name:"kontrak_id",
        field:"kontrak_awal_id"
    }
})
PengaturanPerpanjanganKontrakOtomatis.belongsTo(Kontrak,{
    as:"kontrakAwal",
    foreignKey:{
        name:"kontrak_id",
        field:"kontrak_awal_id"
    }
})

Kontrak.hasMany(PengaturanPerpanjanganKontrakOtomatis,{
    as:"pengaturanPerpanjanganTerakhir",
    foreignKey:"kontrak_terakhir_id"
})
PengaturanPerpanjanganKontrakOtomatis.belongsTo(Kontrak,{
    as:"kontrakTerakhir",
    foreignKey:"kontrak_terakhir_id"
})
