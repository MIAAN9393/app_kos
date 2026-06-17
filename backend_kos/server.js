const express = require("express");
require("dotenv").config();
const sequelize = require("./config/database");
require("./model/index");
const { starCronjob } = require("./cron/index_cron");

const app = express();
app.use(express.json());

// Test route
app.get("/awal",(req,res)=>{
  res.status(200).json({
    pesan: "ini testing buat lo yang goblok",
    token: "12345665432",
    data:{
      kata_kata: ["kamu harus semangat","jangan berhenti kalau kamu berhenti semua ini akan sia sia kamu paham itu kan"]
    }
  })
})
app.use('/api/auth',require("./routes/user_routes"))
app.use('/api/kos',require("./routes/kos_routes"))
app.use('/api/kamar',require("./routes/kamar_routes"))
app.use('/api/penyewa',require("./routes/penyewa_routes"))
app.use('/api/kontrak',require("./routes/kontrak_routes"))
app.use('/api/tagihan',require("./routes/tagihan_routes"))
app.use('/api/pembayaran',require("./routes/pembayaran_routes"))
app.use('/api/laporan_keuangan',require("./routes/laporan_keuangan_routes"))
app.use('/api/laporan_tagihan',require("./routes/laporan_tagihan_routes"))
app.use('/api/dashboard',require("./routes/dashboard_routes"))
app.use('/api/profile',require("./routes/profile_routes"))
app.use('/api/whatsapp',require("./routes/whatsapp_routes"))
app.use('/api/pengaturan-otomatis',require("./routes/pengaturan_otomatis_routes"))
app.use('/api/fcm',require("./routes/fcm_routes"))

app.use(require("./middleware/error_middleware"))
// Test koneksi DB
sequelize.authenticate()
  .then(() => {
    console.log("Database connected");
    starCronjob();
    app.listen(process.env.PORT, () => {
      console.log(`Server running on port ${process.env.PORT}`);
    });
  })
  .catch(err => {
    console.error("Unable to connect:", err);
  });
