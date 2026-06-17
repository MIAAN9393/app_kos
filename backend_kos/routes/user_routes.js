const express = require("express");
const router = express.Router();

const userController = require("../controller/user_controller");

router.post("/register", userController.register);

router.post("/login", userController.login);

router.post("/google", userController.login_google);

router.post("/resend-email-verification", userController.resend_email_verification);

router.post("/resend-phone-verification", userController.resend_phone_verification);

router.post("/verify-email", userController.verify_email);

router.post("/verify-phone", userController.verify_phone);

router.post("/forgot-password", userController.forgot_password);

router.post("/reset-password", userController.reset_password);

router.post("/logout", userController.logout);

module.exports = router;
