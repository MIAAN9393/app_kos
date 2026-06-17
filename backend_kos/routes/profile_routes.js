const express = require("express")
const router = express.Router()
const authMiddleware = require("../middleware/auth_middleware")
const profileController = require("../controller/profile_controller")
const { uploadFotoProfile } = require("../middleware/profile_upload_middleware")

const hanyaPemilik = authMiddleware.cek_token_and_role(["pemilik"])

router.get("/", hanyaPemilik, profileController.ambilProfile)
router.put("/", hanyaPemilik, uploadFotoProfile, profileController.updateProfile)
router.put("/password", hanyaPemilik, profileController.gantiPassword)

module.exports = router
