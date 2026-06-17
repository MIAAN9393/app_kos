const { throwError } = require("../utils/error")

const GRAPH_VERSION = process.env.WHATSAPP_GRAPH_VERSION || "v21.0"
const GRAPH_BASE_URL = `https://graph.facebook.com/${GRAPH_VERSION}`

function sanitizeMetaError(payload, fallback) {
  const error = payload?.error || {}
  const code = error.code
  const subcode = error.error_subcode
  const message = `${error.message || ""}`.toLowerCase()

  if (code === 190 || message.includes("access token")) {
    return "Access token tidak valid atau expired."
  }

  if (
    code === 100 ||
    subcode === 33 ||
    message.includes("unsupported get request") ||
    message.includes("does not exist")
  ) {
    return "Phone Number ID tidak valid."
  }

  return fallback
}

async function parseMetaResponse(response, fallback = "Gagal menghubungi WhatsApp Cloud API.") {
  let payload = null
  try {
    payload = await response.json()
  } catch (_) {
    payload = null
  }

  if (!response.ok) {
    const message = sanitizeMetaError(payload, fallback)
    throwError(message, response.status >= 500 ? 502 : 400, "WHATSAPP_META_ERROR")
  }

  return payload || {}
}

async function requestMeta(path, { method = "GET", access_token, body } = {}) {
  if (typeof fetch !== "function") {
    throwError(
      "Runtime Node belum mendukung fetch untuk WhatsApp Cloud API.",
      500,
      "FETCH_NOT_AVAILABLE"
    )
  }

  if (!access_token) {
    throwError("Access token wajib diisi", 400, "WHATSAPP_ACCESS_TOKEN_REQUIRED")
  }

  const response = await fetch(`${GRAPH_BASE_URL}${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${access_token}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  })

  try {
    return await parseMetaResponse(response)
  } catch (error) {
    if (error.code === "WHATSAPP_META_ERROR") {
      const fallback =
        method === "GET"
          ? "Koneksi WhatsApp gagal."
          : "Gagal mengirim pesan WhatsApp."
      if (error.message === "Gagal menghubungi WhatsApp Cloud API.") {
        throwError(fallback, error.status || 400, error.code)
      }
    }
    throw error
  }
}

exports.testConnection = async ({ phone_number_id, access_token }) => {
  if (!phone_number_id) {
    throwError(
      "Phone Number ID wajib diisi",
      400,
      "WHATSAPP_PHONE_NUMBER_ID_REQUIRED"
    )
  }

  const data = await requestMeta(
    `/${encodeURIComponent(phone_number_id)}?fields=id,display_phone_number,verified_name`,
    { access_token }
  )

  return {
    status: "connected",
    phone_number_id: data.id || phone_number_id,
    display_phone_number: data.display_phone_number || null,
    verified_name: data.verified_name || null,
  }
}

exports.sendTextMessage = async ({
  phone_number_id,
  access_token,
  to,
  message,
}) => {
  if (!phone_number_id) {
    throwError(
      "Phone Number ID wajib diisi",
      400,
      "WHATSAPP_PHONE_NUMBER_ID_REQUIRED"
    )
  }

  const text = String(message || "").trim()
  if (!text) {
    throwError("Pesan wajib diisi", 400, "WHATSAPP_MESSAGE_REQUIRED")
  }

  const data = await requestMeta(
    `/${encodeURIComponent(phone_number_id)}/messages`,
    {
      method: "POST",
      access_token,
      body: {
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to,
        type: "text",
        text: {
          preview_url: false,
          body: text,
        },
      },
    }
  )

  return {
    status: "sent",
    message_id: data.messages?.[0]?.id || null,
    to,
  }
}

exports.uploadDocumentMedia = async ({
  phone_number_id,
  access_token,
  buffer,
  filename,
  mime_type,
}) => {
  if (typeof fetch !== "function" || typeof FormData !== "function" || typeof Blob !== "function") {
    throwError(
      "Runtime Node belum mendukung upload media WhatsApp.",
      500,
      "FORMDATA_NOT_AVAILABLE"
    )
  }

  if (!phone_number_id) {
    throwError(
      "Phone Number ID wajib diisi",
      400,
      "WHATSAPP_PHONE_NUMBER_ID_REQUIRED"
    )
  }

  if (!access_token) {
    throwError("Access token wajib diisi", 400, "WHATSAPP_ACCESS_TOKEN_REQUIRED")
  }

  if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
    throwError("File PDF invoice kosong.", 400, "WHATSAPP_EMPTY_MEDIA")
  }

  const form = new FormData()
  form.append("messaging_product", "whatsapp")
  form.append("type", mime_type || "application/pdf")
  form.append("file", new Blob([buffer], { type: mime_type || "application/pdf" }), filename)

  const response = await fetch(
    `${GRAPH_BASE_URL}/${encodeURIComponent(phone_number_id)}/media`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${access_token}`,
      },
      body: form,
    }
  )

  const data = await parseMetaResponse(response, "Gagal upload media WhatsApp.")
  if (!data.id) {
    throwError("Gagal upload media WhatsApp.", 400, "WHATSAPP_MEDIA_UPLOAD_FAILED")
  }

  return {
    media_id: data.id,
  }
}

exports.sendDocumentMessage = async ({
  phone_number_id,
  access_token,
  to,
  media_id,
  filename,
  caption,
}) => {
  if (!media_id) {
    throwError("Media ID WhatsApp wajib diisi", 400, "WHATSAPP_MEDIA_ID_REQUIRED")
  }

  const data = await requestMeta(
    `/${encodeURIComponent(phone_number_id)}/messages`,
    {
      method: "POST",
      access_token,
      body: {
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to,
        type: "document",
        document: {
          id: media_id,
          filename,
          caption,
        },
      },
    }
  )

  return {
    status: "sent",
    message_id: data.messages?.[0]?.id || null,
    to,
  }
}
