const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware')

const kamarController = require("../controller/kamar_controller");

router.get("/ambil_kamar/:id",authMiddleware.cek_token_and_role(["pemilik"]), kamarController.ambil_kamar);

router.post("/buat_kamar/:id",authMiddleware.cek_token_and_role(["pemilik"]), kamarController.buat_kamar);

router.put("/edit_kamar/:id",authMiddleware.cek_token_and_role(["pemilik"]), kamarController.edit_kamar);

router.put("/shapus_kamar/:id",authMiddleware.cek_token_and_role(["pemilik"]), kamarController.shapus_kamar);

module.exports = router;