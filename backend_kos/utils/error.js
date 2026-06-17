/**
 * Lempar error API — dukung dua gaya pemanggilan:
 * - throwError("pesan", 400, "CODE")
 * - throwError(400, "pesan", "CODE")  // gaya lama di validator
 */
function throwError(arg1, arg2, arg3 = "VALIDATION_ERROR") {
  let message
  let status
  let code

  if (typeof arg1 === "number") {
    status = arg1
    message = String(arg2 ?? "Terjadi kesalahan")
    code = typeof arg3 === "string" ? arg3 : "VALIDATION_ERROR"
  } else {
    message = String(arg1 ?? "Terjadi kesalahan")
    status = typeof arg2 === "number" ? arg2 : 400
    code = typeof arg3 === "string" ? arg3 : "VALIDATION_ERROR"
  }

  const error = new Error(message)
  error.status = status
  error.code = code
  throw error
}

module.exports = {
  throwError,
}
