const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware')

const tagihanController = require("../controller/tagihan_controller");

router.get("/ambil_semua_tagihan",authMiddleware.cek_token_and_role(["pemilik"]), tagihanController.ambil_semua_tagihan);

router.get("/ambil_tagihan/:id",authMiddleware.cek_token_and_role(["pemilik"]), tagihanController.ambil_Tagihan);

router.post("/buat_tagihan/",authMiddleware.cek_token_and_role(["pemilik"]), tagihanController.buat_tagihan);

router.put("/edit_tagihan/:id",authMiddleware.cek_token_and_role(["pemilik"]), tagihanController.edit_tagihan);

router.put("/shapus_tagihan/:id",authMiddleware.cek_token_and_role(["pemilik"]), tagihanController.shapus_tagihan);

module.exports = router;