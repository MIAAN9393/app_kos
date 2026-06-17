const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware')

const penyewaController = require("../controller/penyewa_controller");

router.get("/ambil_penyewa/:id",authMiddleware.cek_token_and_role(["pemilik"]), penyewaController.ambil_penyewa);

router.get("/list_by_kos/:id",authMiddleware.cek_token_and_role(["pemilik"]), penyewaController.list_by_kos);

router.post("/buat_penyewa",authMiddleware.cek_token_and_role(["pemilik"]), penyewaController.buat_penyewa);

router.put("/edit_penyewa/:id",authMiddleware.cek_token_and_role(["pemilik"]), penyewaController.edit_penyewa);

router.put("/shapus_penyewa/:id",authMiddleware.cek_token_and_role(["pemilik"]), penyewaController.shapus_penyewa);

router.get("/ambil_semua_penyewa",authMiddleware.cek_token_and_role(["pemilik"]), penyewaController.ambil_semua_penyewa);

module.exports = router;