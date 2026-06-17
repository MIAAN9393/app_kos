const { CronJob } = require("cron")
const pengaturanTagihanOtomatisService = require("../services/pengaturan_tagihan_otomatis_service")

exports.startTagihanOtomatisCron = () => {
  const schedule = process.env.CRON_TAGIHAN_OTOMATIS_SCHEDULE || "10 0 * * *"
  const timeZone = process.env.CRON_TIMEZONE || "Asia/Jakarta"

  const job = new CronJob(
    schedule,
    async () => {
      console.log("[cron:tagihan-otomatis] mulai generate")

      try {
        const hasil = await pengaturanTagihanOtomatisService.generateTagihanOtomatis()
        console.log("[cron:tagihan-otomatis] selesai", hasil)
      } catch (error) {
        console.error("[cron:tagihan-otomatis] gagal", error)
      }
    },
    null,
    false,
    timeZone
  )

  job.start()
  console.log(`[cron:tagihan-otomatis] dijadwalkan: ${schedule} (${timeZone})`)

  return job
}
