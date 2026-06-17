const { JWT } = require("google-auth-library")
const { createHash, createPrivateKey } = require("crypto")
const { Op } = require("sequelize")
const FcmToken = require("../model/fcm_token")

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

let cachedClient = null
let cachedCredentialFingerprint = null

const normalizePrivateKey = (key) => {
  if (!key) return null

  let value = String(key).trim()

  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    value = value.slice(1, -1)
  }

  return value
    .replace(/\\\\n/g, "\n")
    .replace(/\\n/g, "\n")
    .replace(/\r\n/g, "\n")
}

const validatePrivateKey = (privateKey) => {
  if (
    !privateKey.includes("-----BEGIN PRIVATE KEY-----") ||
    !privateKey.includes("-----END PRIVATE KEY-----")
  ) {
    throw new Error(
      "FIREBASE_PRIVATE_KEY tidak valid: pastikan memakai private_key service account lengkap dengan BEGIN/END PRIVATE KEY."
    )
  }

  try {
    createPrivateKey(privateKey)
  } catch (_) {
    throw new Error(
      "FIREBASE_PRIVATE_KEY tidak bisa dibaca OpenSSL. Pastikan newline memakai \\n dan value dibungkus quote di .env."
    )
  }
}

const getCredentials = () => ({
  project_id: process.env.FIREBASE_PROJECT_ID,
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  private_key: normalizePrivateKey(process.env.FIREBASE_PRIVATE_KEY),
})

const validateCredentials = () => {
  const credentials = getCredentials()
  const missing = []

  if (!credentials.project_id) missing.push("FIREBASE_PROJECT_ID")
  if (!credentials.client_email) missing.push("FIREBASE_CLIENT_EMAIL")
  if (!credentials.private_key) missing.push("FIREBASE_PRIVATE_KEY")

  if (missing.length > 0) {
    throw new Error(`Konfigurasi FCM belum lengkap: ${missing.join(", ")}`)
  }

  validatePrivateKey(credentials.private_key)

  return credentials
}

const credentialFingerprint = (credentials) =>
  createHash("sha256")
    .update(
      [
        credentials.project_id,
        credentials.client_email,
        credentials.private_key,
      ].join("|")
    )
    .digest("hex")

const getClient = () => {
  const credentials = validateCredentials()
  const fingerprint = credentialFingerprint(credentials)

  if (cachedClient && cachedCredentialFingerprint === fingerprint) {
    return cachedClient
  }

  cachedClient = new JWT({
    email: credentials.client_email,
    key: credentials.private_key,
    scopes: [FCM_SCOPE],
  })
  cachedCredentialFingerprint = fingerprint

  return cachedClient
}

const getAccessToken = async () => {
  const client = getClient()

  const result = await client.getAccessToken()
  return typeof result === "string" ? result : result?.token
}

const safeData = (data = {}) =>
  Object.fromEntries(
    Object.entries(data)
      .filter(([, value]) => value !== undefined && value !== null)
      .map(([key, value]) => [key, String(value)])
  )

const markTokenNonaktif = async (token) => {
  try {
    await FcmToken.update(
      { status: "nonaktif" },
      { where: { token, status: "aktif" } }
    )
  } catch (error) {
    console.error("[fcm] gagal nonaktifkan token", error?.message || error)
  }
}

exports.registerToken = async (user_id, { token, platform = "android" }) => {
  if (!user_id) throw new Error("user_id wajib diisi")
  if (!token || !String(token).trim()) throw new Error("token FCM wajib diisi")

  const tokenValue = String(token).trim()
  const platformValue = ["android", "ios", "web"].includes(platform)
    ? platform
    : "android"

  const existing = await FcmToken.findOne({ where: { token: tokenValue } })

  if (existing) {
    await existing.update({
      user_id,
      platform: platformValue,
      status: "aktif",
    })
    return existing
  }

  return FcmToken.create({
    user_id,
    token: tokenValue,
    platform: platformValue,
    status: "aktif",
  })
}

exports.unregisterToken = async (user_id, token) => {
  if (!user_id || !token) return 0

  const [count] = await FcmToken.update(
    { status: "nonaktif" },
    {
      where: {
        user_id,
        token: String(token).trim(),
        status: "aktif",
      },
    }
  )

  return count
}

exports.sendToUser = async (user_id, payload = {}) => {
  if (!user_id) return { sent: 0, failed: 0, skipped: 1 }

  const tokens = await FcmToken.findAll({
    attributes: ["token"],
    where: {
      user_id,
      status: "aktif",
      token: { [Op.ne]: null },
    },
  })

  if (tokens.length === 0) return { sent: 0, failed: 0, skipped: 1 }

  const credentials = validateCredentials()
  const accessToken = await getAccessToken()
  const projectId = credentials.project_id
  if (!accessToken || !projectId || typeof fetch !== "function") {
    return { sent: 0, failed: 0, skipped: tokens.length }
  }

  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`
  const result = { sent: 0, failed: 0, skipped: 0 }

  for (const row of tokens) {
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: row.token,
            notification: {
              title: payload.title || "Kos Management",
              body: payload.body || "",
            },
            data: safeData(payload.data),
          },
        }),
      })

      if (res.ok) {
        result.sent += 1
        continue
      }

      result.failed += 1
      const body = await res.text()
      if (res.status === 404 || body.includes("UNREGISTERED")) {
        await markTokenNonaktif(row.token)
      }
      console.error("[fcm] gagal kirim notif", res.status, body)
    } catch (error) {
      result.failed += 1
      console.error("[fcm] gagal kirim notif", error?.message || error)
    }
  }

  return result
}
