exports.ambil_tanggal_doang = (date) => {

  const d = new Date(date)

  return new Date(
    d.getFullYear(),
    d.getMonth(),
    d.getDate()
  )
}

exports.ambil_tanggal_timezone = (
  date = new Date(),
  timeZone = process.env.CRON_TIMEZONE || "Asia/Jakarta"
) => {
  const d = new Date(date)
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(d)

  const map = Object.fromEntries(parts.map((part) => [part.type, part.value]))

  return `${map.year}-${map.month}-${map.day}`
}

const pad = (value) => String(value).padStart(2, "0")

const parse_tanggal_mysql = (value) => {
  if (!value) return null

  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) return null
    return new Date(value.getFullYear(), value.getMonth(), value.getDate())
  }

  const text = String(value).trim().split("T")[0]
  const parts = text.split("-")
  if (parts.length !== 3) return null

  const year = Number(parts[0])
  const month = Number(parts[1])
  const day = Number(parts[2])
  if (!year || !month || !day) return null

  const date = new Date(year, month - 1, day)
  return Number.isNaN(date.getTime()) ? null : date
}

const format_tanggal_mysql = (date) => {
  const d = parse_tanggal_mysql(date)
  if (!d) return null
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

const tambah_bulan = (tanggal, jumlah_bulan) => {
  const d = parse_tanggal_mysql(tanggal)
  if (!d) return null

  const day = d.getDate()
  const target = new Date(d.getFullYear(), d.getMonth() + jumlah_bulan, 1)
  const lastDay = new Date(target.getFullYear(), target.getMonth() + 1, 0).getDate()
  target.setDate(Math.min(day, lastDay))
  return target
}

exports.parse_tanggal_mysql = parse_tanggal_mysql

exports.format_tanggal_mysql = format_tanggal_mysql

exports.tambah_hari = (tanggal, jumlah_hari) => {
  const d = parse_tanggal_mysql(tanggal)
  if (!d) return null
  d.setDate(d.getDate() + Number(jumlah_hari || 0))
  return format_tanggal_mysql(d)
}

exports.kurang_hari = (tanggal, jumlah_hari) => {
  return exports.tambah_hari(tanggal, -Number(jumlah_hari || 0))
}

exports.tambah_periode = (tanggal, siklus = "bulanan", jumlah = 1) => {
  const total = Number(jumlah || 1)

  if (siklus === "harian") {
    return exports.tambah_hari(tanggal, total)
  }

  if (siklus === "mingguan") {
    return exports.tambah_hari(tanggal, total * 7)
  }

  if (siklus === "tahunan") {
    return format_tanggal_mysql(tambah_bulan(tanggal, total * 12))
  }

  return format_tanggal_mysql(tambah_bulan(tanggal, total))
}

exports.hitung_akhir_periode = (tanggal_mulai, siklus = "bulanan", jumlah = 1) => {
  return exports.kurang_hari(
    exports.tambah_periode(tanggal_mulai, siklus, jumlah),
    1
  )
}

exports.hitung_tanggal_mulai_berikutnya = (periode_akhir) => {
  return exports.tambah_hari(periode_akhir, 1)
}
