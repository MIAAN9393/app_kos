const kamarService = require("../services/kamar_service");

exports.ambil_kamar = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const kos_id = req.params.id;

  try {
    const data = await kamarService.ambil_kamar(pemilik_id, kos_id);

    res.status(200).json({
      success: true,
      code: "KAMAR_LIST_SUCCESS",
      pesan: "ini daftar kamar kamu",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.buat_kamar = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const kos_id = req.params.id;
  const body = req.body;

  try {
    const data = await kamarService.buat_kamar(pemilik_id, kos_id, body);

    res.status(200).json({
      success: true,
      code: "KAMAR_CREATED",
      pesan: "kamar berhasil di buat",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.edit_kamar = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const kamar_id = req.params.id;
  const body = req.body;

  try {
    const data = await kamarService.edit_kamar(pemilik_id, kamar_id, body);

    res.status(200).json({
      success: true,
      code: "KAMAR_UPDATED",
      pesan: "kamar berhasil di update",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.shapus_kamar = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const kamar_id = req.params.id;

  try {
    const data = await kamarService.shapus_kamar(pemilik_id, kamar_id);

    res.status(200).json({
      success: true,
      code: "KAMAR_DELETED",
      pesan: "kamar berhasil di hapus",
      data,
    });
  } catch (error) {
    next(error);
  }
};
