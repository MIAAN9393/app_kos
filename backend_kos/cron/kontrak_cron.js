const { CronJob } = require("cron")
const sinkronisasiService = require("../services/sinkronisasi_service")

exports.startKontrakCron = () => {
  const schedule = process.env.CRON_KONTRAK_SCHEDULE || "2 0 * * *"
  const timeZone = process.env.CRON_TIMEZONE || "Asia/Jakarta"

  const job = new CronJob(
    schedule,
    async () => {
    console.log("[cron:kontrak] mulai sinkronisasi")

    try {
      const hasil = await sinkronisasiService.syncKontrakDanKamar()
      console.log("[cron:kontrak] selesai", hasil)
    } catch (error) {
      console.error("[cron:kontrak] gagal", error)
    }
    },
    null,
    false,
    timeZone
  )

  job.start()
  console.log(`[cron:kontrak] dijadwalkan: ${schedule} (${timeZone})`)

  return job
}
