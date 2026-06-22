const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/auth_middleware");
const subscriptionController = require("../controller/subscription_controller");

router.get(
  "/me",
  authMiddleware.cek_token_and_role(["pemilik"]),
  subscriptionController.ambil_subscription_saya
);

module.exports = router;
