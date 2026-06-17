const kontrakService = require("../services/kontrak_service");

exports.ambil_kontrak = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const penyewa_id = req.params.id;

  try {
    const data = await kontrakService.ambil_kontrak(pemilik_id,penyewa_id)

    res.status(200).json({
      success: true,
      code: "GET_KONTRAK_SUCCESS",
      pesan: "ini kontrak",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.ambil_semua_kontrak = async (req, res, next) => {
  const pemilik_id = req.user.id;

  try {
    const data = await kontrakService.ambil_semua_kontrak(pemilik_id)

    res.status(200).json({
      success: true,
      code: "KONTRAK_LIST_SUCCESS",
      pesan: "ini semua kontrak kamu",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.list_by_penyewa = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const penyewa_id = req.params.id;

  try {
    const data = await kontrakService.list_by_penyewa(pemilik_id, penyewa_id)

    res.status(200).json({
      success: true,
      code: "KONTRAK_BY_PENYEWA_SUCCESS",
      pesan: "ini riwayat kontrak penyewa",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.buat_kontrak = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const body = req.body;

  try {
    const data = await kontrakService.buat_kontrak(pemilik_id,body)

    res.status(200).json({
      success: true,
      code: "KONTRAK_CREATED",
      pesan: "kontrak berhasil di buat",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.edit_kontrak = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const kontrak_id = req.params.id;
  const body = req.body;

  try {
    const data = await kontrakService.edit_kontrak(pemilik_id,kontrak_id,body)

    res.status(200).json({
      success: true,
      code: "KONTRAK_UPDATED",
      pesan: "kontrak berhasil di update",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.shapus_kontrak = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const kontrak_id = req.params.id;

  try {
    const data = await kontrakService.hapus_kontrak(pemilik_id, kontrak_id);

    res.status(200).json({
      success: true,
      code: "KONTRAJ_DELETED",
      pesan: "kontrak berhasil di hapus",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.selesai_kontrak = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const kontrak_id = req.params.id;

  try {
    const data = await kontrakService.selsaikan_kontrak(pemilik_id, kontrak_id);

    res.status(200).json({
      success: true,
      code: "KONTRAK_FINISHED",
      pesan: "kontrak berhasil diselesaikan",
      data,
    });
  } catch (error) {
    next(error);
  }
};
