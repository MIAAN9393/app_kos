const express = require("express")
const router = express.Router()
const authMiddleware = require("../middleware/auth_middleware")
const whatsappController = require("../controller/whatsapp_controller")

const hanyaPemilik = authMiddleware.cek_token_and_role(["pemilik"])

router.get("/settings", hanyaPemilik, whatsappController.ambilSettings)
router.put("/settings", hanyaPemilik, whatsappController.simpanSettings)
router.get("/message-logs", hanyaPemilik, whatsappController.ambilMessageLogs)
router.post("/test-connection", hanyaPemilik, whatsappController.tesKoneksi)
router.post("/send-test-message", hanyaPemilik, whatsappController.kirimPesanTest)
router.post(
  "/tagihan/:tagihan_id/send-invoice",
  hanyaPemilik,
  whatsappController.kirimInvoiceTagihan
)
router.post(
  "/kontrak/:kontrak_id/send-kontrak",
  hanyaPemilik,
  whatsappController.kirimKontrak
)

module.exports = router
