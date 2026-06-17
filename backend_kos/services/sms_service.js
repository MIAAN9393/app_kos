exports.kirimOtp = async ({ to, title, code, expiresMinutes }) => {
  const message = `${title}. Kode OTP: ${code}. Berlaku ${expiresMinutes} menit.`

  if (!process.env.SMS_WEBHOOK_URL) {
    console.log(`[sms:dev] ${title} untuk ${to}. OTP: ${code}`)
    return { sent: false, reason: "SMS_NOT_CONFIGURED" }
  }

  const response = await fetch(process.env.SMS_WEBHOOK_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(process.env.SMS_API_KEY
        ? { Authorization: `Bearer ${process.env.SMS_API_KEY}` }
        : {}),
    },
    body: JSON.stringify({
      to,
      message,
    }),
  })

  if (!response.ok) {
    const body = await response.text().catch(() => "")
    const error = new Error(`gagal mengirim SMS (${response.status}) ${body}`)
    error.status = 502
    error.code = "SMS_SEND_FAILED"
    throw error
  }

  return { sent: true }
}
