const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware')

const kosController = require("../controller/kos_controller");

router.get("/ambil_kos", authMiddleware.cek_token_and_role(["pemilik"]), kosController.ambil_kos);

router.get("/laporan_kos", authMiddleware.cek_token_and_role(["pemilik"]), kosController.laporan_kos);

router.post("/buat_kos", authMiddleware.cek_token_and_role(["pemilik"]), kosController.buat_kos);

router.put("/edit_kos/:id",authMiddleware.cek_token_and_role(["pemilik"]),  kosController.edit_kos);

router.put("/shapus_kos/:id",authMiddleware.cek_token_and_role(["pemilik"]),  kosController.shapus_kos);

module.exports = router;