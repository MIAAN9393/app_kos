const multer = require("multer")

const allowedMimeTypes = ["image/jpeg", "image/png", "image/webp"]

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 2 * 1024 * 1024,
  },
  fileFilter: (req, file, cb) => {
    if (!allowedMimeTypes.includes(file.mimetype)) {
      const error = new Error("foto profile harus berupa image jpg, jpeg, png, atau webp")
      error.status = 400
      error.code = "INVALID_PROFILE_IMAGE"
      return cb(error)
    }

    cb(null, true)
  },
}).single("foto")

exports.uploadFotoProfile = (req, res, next) => {
  upload(req, res, (error) => {
    if (!error) return next()

    if (error instanceof multer.MulterError && error.code === "LIMIT_FILE_SIZE") {
      error.status = 400
      error.code = "PROFILE_IMAGE_TOO_LARGE"
      error.message = "ukuran foto profile maksimal 2MB"
    }

    next(error)
  })
}
