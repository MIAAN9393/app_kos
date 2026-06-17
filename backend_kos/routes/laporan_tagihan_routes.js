const express = require("express")
const router = express.Router()
const authMiddleware = require("../middleware/auth_middleware")
const laporanTagihanController = require("../controller/laporan_tagihan_controller")

router.get(
  "/ambil_laporan_tagihan",
  authMiddleware.cek_token_and_role(["pemilik"]),
  laporanTagihanController.ambil_laporan_tagihan
)

module.exports = router
