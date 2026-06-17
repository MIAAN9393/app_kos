const PembayaranService = require("../services/pembayaran_service");

exports.ambil_pembayaran = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const tagihan_id = req.params.id;

  try {
    const data = await PembayaranService.ambil_pembayaran(pemilik_id,tagihan_id)

    res.status(200).json({
      success: true,
      code: "LIST_PEMBAYARAN_SUCCESS",
      pesan: "ini pembayaran kamu",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.ambil_semua_pembayaran = async (req, res, next) => {
  const pemilik_id = req.user.id;

  try {
    const data = await PembayaranService.ambil_semua_pembayaran(pemilik_id)

    res.status(200).json({
      success: true,
      code: "PEMBAYARAN_LIST_SUCCESS",
      pesan: "ini semua pembayaran kamu",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.buat_pembayaran = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const body = req.body;

  try {
    const data = await PembayaranService.buat_pembayaran(pemilik_id,body)

    res.status(200).json({
      success: true,
      code: "PEMBAYARAN_CREATED",
      pesan: "pembayaran berhasil di buat",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.buat_refund_pembayaran = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const body = req.body;

  try {
    const data = await PembayaranService.buat_refund_pembayaran(pemilik_id,body)

    res.status(200).json({
      success: true,
      code: "PEMBAYARAN_REFUND",
      pesan: "pembayarab berhasil di refund",
      data,
    });
  } catch (error) {
    next(error);
  }
};
