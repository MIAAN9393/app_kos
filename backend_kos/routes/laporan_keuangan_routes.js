const express = require("express")
const router = express.Router()
const authMiddleware = require("../middleware/auth_middleware")
const laporanKeuanganController = require("../controller/laporan_keuangan_controller")

router.get(
  "/ambil_laporan_keuangan",
  authMiddleware.cek_token_and_role(["pemilik"]),
  laporanKeuanganController.ambil_laporan_keuangan
)

module.exports = router
