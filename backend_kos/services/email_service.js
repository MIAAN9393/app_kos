const nodemailer = require("nodemailer")

let transporter = null

function smtpConfigured() {
  return Boolean(process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS)
}

function getTransporter() {
  if (!smtpConfigured()) return null
  if (transporter) return transporter

  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === "true",
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  })

  return transporter
}

exports.kirimOtp = async ({ to, subject, title, code, expiresMinutes }) => {
  const mailer = getTransporter()
  const from = process.env.SMTP_FROM || process.env.SMTP_USER
  const text = `${title}\n\nKode OTP: ${code}\nBerlaku ${expiresMinutes} menit. Jangan bagikan kode ini ke siapa pun.`

  if (!mailer) {
    console.log(`[email:dev] ${subject} untuk ${to}. OTP: ${code}`)
    return { sent: false, reason: "SMTP_NOT_CONFIGURED" }
  }

  await mailer.sendMail({
    from,
    to,
    subject,
    text,
    html: `
      <div style="font-family:Arial,sans-serif;line-height:1.5;color:#111827">
        <h2>${title}</h2>
        <p>Kode OTP kamu:</p>
        <p style="font-size:28px;font-weight:700;letter-spacing:6px">${code}</p>
        <p>Kode berlaku ${expiresMinutes} menit. Jangan bagikan kode ini ke siapa pun.</p>
      </div>
    `,
  })

  return { sent: true }
}
