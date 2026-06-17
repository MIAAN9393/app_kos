const { startKontrakCron } = require("./kontrak_cron")
const { startTagihanCron } = require("./tagihan_cron")
const { startTagihanOtomatisCron } = require("./tagihan_otomatis_cron")
const {
  startPerpanjanganKontrakOtomatisCron,
} = require("./perpanjangan_kontrak_otomatis_cron")

let jobs = null

exports.starCronjob = () => {
  if (jobs) {
    console.log("[cron] sudah berjalan, tidak membuat job baru")
    return jobs
  }

  jobs = [
    startKontrakCron(),
    startTagihanCron(),
    startTagihanOtomatisCron(),
    startPerpanjanganKontrakOtomatisCron(),
  ]

  return jobs
}

exports.startCronjob = exports.starCronjob
