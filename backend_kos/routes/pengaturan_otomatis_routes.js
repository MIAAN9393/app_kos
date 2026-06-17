const express = require("express")
const router = express.Router()
const authMiddleware = require("../middleware/auth_middleware")
const controller = require("../controller/pengaturan_otomatis_controller")

const pemilikOnly = authMiddleware.cek_token_and_role(["pemilik"])

router.get(
  "/tagihan/:kontrak_id",
  pemilikOnly,
  controller.ambil_tagihan_otomatis
)
router.put(
  "/tagihan/:kontrak_id",
  pemilikOnly,
  controller.simpan_tagihan_otomatis
)
router.put(
  "/tagihan/:kontrak_id/status",
  pemilikOnly,
  controller.ubah_status_tagihan_otomatis
)

router.get(
  "/perpanjangan-kontrak/:kontrak_id",
  pemilikOnly,
  controller.ambil_perpanjangan_otomatis
)
router.put(
  "/perpanjangan-kontrak/:kontrak_id",
  pemilikOnly,
  controller.simpan_perpanjangan_otomatis
)
router.put(
  "/perpanjangan-kontrak/:kontrak_id/status",
  pemilikOnly,
  controller.ubah_status_perpanjangan_otomatis
)

module.exports = router
