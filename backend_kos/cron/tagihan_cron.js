const { CronJob } = require("cron")
const sinkronisasiService = require("../services/sinkronisasi_service")

exports.startTagihanCron = () => {
  const schedule = process.env.CRON_TAGIHAN_SCHEDULE || "5 0 * * *"
  const timeZone = process.env.CRON_TIMEZONE || "Asia/Jakarta"

  const job = new CronJob(
    schedule,
    async () => {
    console.log("[cron:tagihan] mulai sinkronisasi")

    try {
      const hasil = await sinkronisasiService.syncTagihan()
      console.log("[cron:tagihan] selesai", hasil)
    } catch (error) {
      console.error("[cron:tagihan] gagal", error)
    }
    },
    null,
    false,
    timeZone
  )

  job.start()
  console.log(`[cron:tagihan] dijadwalkan: ${schedule} (${timeZone})`)

  return job
}

exports.cront_tagihan = exports.startTagihanCron
