const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/auth_middleware");
const midtransController = require("../controller/midtrans_controller");

router.post(
  "/subscription/create",
  authMiddleware.cek_token_and_role(["pemilik"]),
  midtransController.create_subscription
);

// Webhook URL di dashboard Midtrans:
// https://domain-backend.com/api/midtrans/notification
router.post("/notification", midtransController.notification);

module.exports = router;
