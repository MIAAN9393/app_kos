const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware')

const kontrakController = require("../controller/kontrak_controller");

router.get("/ambil_semua_kontrak",authMiddleware.cek_token_and_role(["pemilik"]), kontrakController.ambil_semua_kontrak);

router.get("/list_by_penyewa/:id",authMiddleware.cek_token_and_role(["pemilik"]), kontrakController.list_by_penyewa);

router.get("/ambil_kontrak/:id",authMiddleware.cek_token_and_role(["pemilik"]), kontrakController.ambil_kontrak);

router.post("/buat_kontrak/",authMiddleware.cek_token_and_role(["pemilik"]), kontrakController.buat_kontrak);

router.put("/edit_kontrak/:id",authMiddleware.cek_token_and_role(["pemilik"]), kontrakController.edit_kontrak);

router.put("/shapus_kontrak/:id",authMiddleware.cek_token_and_role(["pemilik"]), kontrakController.shapus_kontrak);

router.put("/selesaikan_kontrak/:id",authMiddleware.cek_token_and_role(["pemilik"]), kontrakController.selesai_kontrak);

module.exports = router;