const { CronJob } = require("cron")
const pengaturanPerpanjanganKontrakOtomatisService = require("../services/pengaturan_perpanjangan_kontrak_otomatis_service")

exports.startPerpanjanganKontrakOtomatisCron = () => {
  const schedule = process.env.CRON_PERPANJANGAN_KONTRAK_OTOMATIS_SCHEDULE || "20 0 * * *"
  const timeZone = process.env.CRON_TIMEZONE || "Asia/Jakarta"

  const job = new CronJob(
    schedule,
    async () => {
      console.log("[cron:perpanjangan-kontrak-otomatis] mulai generate")

      try {
        const hasil = await pengaturanPerpanjanganKontrakOtomatisService
          .generatePerpanjanganKontrakOtomatis()
        console.log("[cron:perpanjangan-kontrak-otomatis] selesai", hasil)
      } catch (error) {
        console.error("[cron:perpanjangan-kontrak-otomatis] gagal", error)
      }
    },
    null,
    false,
    timeZone
  )

  job.start()
  console.log(
    `[cron:perpanjangan-kontrak-otomatis] dijadwalkan: ${schedule} (${timeZone})`
  )

  return job
}
