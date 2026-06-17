const TagihanService = require("../services/tagihan_service");

exports.ambil_Tagihan = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const kontrak_id = req.params.id;

  try {
    const data = await TagihanService.ambil_tagihan(pemilik_id,kontrak_id)

    res.status(200).json({
      success: true,
      code: "LIST_TAGIHAN_SUCCESS",
      pesan: "ini tagihan kamu",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.ambil_semua_tagihan = async (req, res, next) => {
  const pemilik_id = req.user.id;

  try {
    const data = await TagihanService.ambil_semua_tagihan(pemilik_id)

    res.status(200).json({
      success: true,
      code: "TAGIHAN_LIST_SUCCESS",
      pesan: "ini semua tagihan kamu",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.buat_tagihan = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const body = req.body;

  try {
    const data = await TagihanService.buat_tagihan(pemilik_id,body)

    res.status(200).json({
      success: true,
      code: "TAGIHAN_CREATED",
      pesan: "tagihan berhasil di buat",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.edit_tagihan = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const tagihan_id = req.params.id;
  const body = req.body;

  try {
    const data = await TagihanService.edit_tagihan(pemilik_id,tagihan_id,body)

    res.status(200).json({
      success: true,
      code: "TAGIHAN_UPDATED",
      pesan: "tagihan berhasil di update",
      data,
    });
  } catch (error) {
    next(error);
  }
};

exports.shapus_tagihan = async (req, res, next) => {
  const pemilik_id = req.user.id;
  const tagihan_id = req.params.id;

  try {
    const data = await TagihanService.hapus_tagihan(pemilik_id, tagihan_id);

    res.status(200).json({
      success: true,
      code: "TAGIHAN_DELETED",
      pesan: "tagihan berhasil di hapus",
      data,
    });
  } catch (error) {
    next(error);
  }
};

