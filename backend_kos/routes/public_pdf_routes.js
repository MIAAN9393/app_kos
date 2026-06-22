const express = require("express")
const publicPdfController = require("../controller/public_pdf_controller")

const router = express.Router()

router.get("/tagihan/:kode_tagihan/pdf", publicPdfController.tagihanPdf)
router.get("/kontrak/:kode_kontrak/pdf", publicPdfController.kontrakPdf)

module.exports = router
