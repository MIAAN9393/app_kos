const invoicePdfService = require("../services/invoice_pdf_service")
const kontrakPdfService = require("../services/kontrak_pdf_service")

function kirimPdf(res, pdf) {
  res.setHeader("Content-Type", "application/pdf")
  res.setHeader("Content-Disposition", `inline; filename="${pdf.filename}"`)
  res.setHeader("Cache-Control", "private, max-age=300")
  return res.status(200).send(pdf.buffer)
}

exports.tagihanPdf = async (req, res, next) => {
  try {
    const pdf = await invoicePdfService.generateInvoicePdfBufferByPublicToken(
      req.params.kode_tagihan,
      req.query.token
    )
    return kirimPdf(res, pdf)
  } catch (error) {
    next(error)
  }
}

exports.kontrakPdf = async (req, res, next) => {
  try {
    const pdf = await kontrakPdfService.generateKontrakPdfBufferByPublicToken(
      req.params.kode_kontrak,
      req.query.token
    )
    return kirimPdf(res, pdf)
  } catch (error) {
    next(error)
  }
}
