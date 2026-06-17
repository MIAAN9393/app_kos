const midtransClient = require("midtrans-client");
require("dotenv").config();

const isProduction = process.env.MIDTRANS_IS_PRODUCTION === "true";

// Server Key tidak boleh dikirim ke Flutter/frontend.
// Flutter hanya menerima snap_token atau redirect_url dari backend.
const snap = new midtransClient.Snap({
  isProduction,
  serverKey: process.env.MIDTRANS_SERVER_KEY,
  clientKey: process.env.MIDTRANS_CLIENT_KEY,
});

module.exports = snap;
