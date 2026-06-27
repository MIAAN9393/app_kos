const { CronJob } = require("cron")
const SubscriptionService = require("../services/subscription_service")

exports.startSubscriptionCron = () => {
  const schedule = process.env.CRON_SUBSCRIPTION_SCHEDULE || "30 0 * * *"
  const timeZone = process.env.CRON_TIMEZONE || "Asia/Jakarta"

  const job = new CronJob(
    schedule,
    async () => {
      console.log("[cron:subscription] mulai sinkronisasi subscription")

      try {
        const hasil = await SubscriptionService.syncSubscriptionLifecycle()
        console.log("[cron:subscription] selesai", hasil)
      } catch (error) {
        console.error("[cron:subscription] gagal", error)
      }
    },
    null,
    false,
    timeZone
  )

  job.start()
  console.log(`[cron:subscription] dijadwalkan: ${schedule} (${timeZone})`)

  return job
}
