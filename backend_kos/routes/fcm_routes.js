const express = require("express")
const router = express.Router()
const authMiddleware = require("../middleware/auth_middleware")
const fcmController = require("../controller/fcm_controller")

const hanyaPemilik = authMiddleware.cek_token_and_role(["pemilik"])

router.post("/register-token", hanyaPemilik, fcmController.registerToken)
router.put("/unregister-token", hanyaPemilik, fcmController.unregisterToken)
router.post("/test-send", hanyaPemilik, fcmController.testSend)
router.post("/test-notification", hanyaPemilik, fcmController.testSend)
router.get("/settings", hanyaPemilik, fcmController.ambilSettings)
router.put("/settings", hanyaPemilik, fcmController.simpanSettings)

module.exports = router
