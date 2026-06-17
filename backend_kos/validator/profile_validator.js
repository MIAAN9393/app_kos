const { throwError } = require("../utils/error")

exports.validasiUpdateProfile = (body) => {
  const nama = `${body.nama ?? ""}`.trim()

  if (!nama) {
    throwError("nama wajib diisi", 400, "VALIDATION_ERROR")
  }

  if (nama.length < 2) {
    throwError("nama minimal 2 karakter", 400, "VALIDATION_ERROR")
  }

  return { nama }
}

exports.validasiGantiPassword = (body) => {
  const password_lama = `${body.password_lama ?? ""}`
  const password_baru = `${body.password_baru ?? ""}`

  if (!password_lama || !password_baru) {
    throwError("password lama dan password baru wajib diisi", 400, "VALIDATION_ERROR")
  }

  if (password_baru.length < 6) {
    throwError("password baru minimal 6 karakter", 400, "VALIDATION_ERROR")
  }

  return { password_lama, password_baru }
}
