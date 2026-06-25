const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
require("dotenv").config();
const sequelize = require("./config/database");
require("./model/index");
const { starCronjob } = require("./cron/index_cron");

const app = express();

const isProduction = process.env.NODE_ENV === "production";
const corsOrigins = (process.env.CORS_ORIGINS || "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(helmet());
app.use(cors({
  origin(origin, callback) {
    if (!origin) return callback(null, true);
    if (!isProduction && corsOrigins.length === 0) return callback(null, true);
    if (corsOrigins.includes(origin)) return callback(null, true);
    const error = new Error("Origin tidak diizinkan oleh CORS");
    error.status = 403;
    error.code = "CORS_ORIGIN_FORBIDDEN";
    return callback(error);
  },
}));
app.use(express.json({ limit: process.env.JSON_BODY_LIMIT || "1mb" }));

const authLimiter = rateLimit({
  windowMs: Number(process.env.AUTH_RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: Number(process.env.AUTH_RATE_LIMIT_MAX) || 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    code: "RATE_LIMITED",
    pesan: "Terlalu banyak percobaan, coba lagi nanti",
  },
});

const publicLimiter = rateLimit({
  windowMs: Number(process.env.PUBLIC_RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: Number(process.env.PUBLIC_RATE_LIMIT_MAX) || 120,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    code: "RATE_LIMITED",
    pesan: "Terlalu banyak permintaan, coba lagi nanti",
  },
});

const webhookLimiter = rateLimit({
  windowMs: Number(process.env.WEBHOOK_RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: Number(process.env.WEBHOOK_RATE_LIMIT_MAX) || 600,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    code: "RATE_LIMITED",
    pesan: "Terlalu banyak request webhook, coba lagi nanti",
  },
});

if (process.env.NODE_ENV !== "production") {
  app.get("/awal", (req, res) => {
    res.status(200).json({
      success: true,
      pesan: "debug route aktif",
    })
  })
}

app.use('/api/auth',authLimiter,require("./routes/user_routes"))
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
app.use('/api/midtrans/notification',webhookLimiter)
app.use('/api/midtrans',require("./routes/midtrans_routes"))
app.use('/api/subscription',require("./routes/subscription_routes"))
app.use('/public',publicLimiter,require("./routes/public_pdf_routes"))
app.get("/",(req,res)=>{
  res.status(200).json({
    sukses:true,
    pesan:"server app-kos terhubung"
  })
})

app.use(require("./middleware/error_middleware"))

async function startServer() {
  try {
    await sequelize.authenticate();
    console.log("Database connected");

    if (process.env.DB_SYNC === "true") {
      await sequelize.sync();
      console.log("Database synced");
    }

    starCronjob();
    app.listen(process.env.PORT, () => {
      console.log(`Server running on port ${process.env.PORT}`);
    });
  } catch (err) {
    console.error("Unable to connect:", err);
    process.exit(1);
  }
}

startServer();
