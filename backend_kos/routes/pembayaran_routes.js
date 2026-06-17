const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware')

const pembayaranController = require("../controller/pembayaran_controller");

router.get("/ambil_semua_pembayaran",authMiddleware.cek_token_and_role(["pemilik"]), pembayaranController.ambil_semua_pembayaran);

router.get("/ambil_pembayaran/:id",authMiddleware.cek_token_and_role(["pemilik"]), pembayaranController.ambil_pembayaran);

router.post("/buat_pembayaran/",authMiddleware.cek_token_and_role(["pemilik"]), pembayaranController.buat_pembayaran);

router.put("/buat_refund_pembayaran/:id",authMiddleware.cek_token_and_role(["pemilik"]), pembayaranController.buat_refund_pembayaran);

module.exports = router;