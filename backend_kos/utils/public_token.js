const crypto = require("crypto")

function buatPublicToken() {
  return crypto.randomBytes(32).toString("hex")
}

async function pastikanPublicToken(row, { transaction } = {}) {
  if (!row) return null
  const current = `${row.public_token || ""}`.trim()
  if (current) return current

  const public_token = buatPublicToken()
  await row.update({ public_token }, { transaction })
  return public_token
}

module.exports = {
  buatPublicToken,
  pastikanPublicToken,
}
