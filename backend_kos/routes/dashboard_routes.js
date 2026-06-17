const express = require("express")
const router = express.Router()
const authMiddleware = require("../middleware/auth_middleware")
const dashboardController = require("../controller/dashboard_controller")

router.get(
  "/ringkasan",
  authMiddleware.cek_token_and_role(["pemilik"]),
  dashboardController.ambil_ringkasan
)

module.exports = router
