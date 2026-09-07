const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');

const uploadsDir = path.join(__dirname, '../../uploads');

function ensureUploadsDir() {
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }
}

function formatDate(value) {
  if (!value) return '—';
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function rupees(amount, currency = 'INR') {
  const n = Number(amount);
  if (!Number.isFinite(n)) return '—';
  return `${currency} ${n.toFixed(2)}`;
}

function generateBookingReceiptPdf(data) {
  ensureUploadsDir();
  const bookingId = String(data.bookingId || 'receipt');
  const fileName = `receipt-${bookingId}.pdf`;
  const filePath = path.join(uploadsDir, fileName);
  const appName = process.env.APP_NAME || '1mg Care';

  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 48, size: 'A4' });
    const stream = fs.createWriteStream(filePath);

    stream.on('finish', () => {
      resolve({
        fileName,
        filePath,
        publicPath: `/uploads/${fileName}`,
      });
    });
    stream.on('error', reject);
    doc.on('error', reject);
    doc.pipe(stream);

    doc.fontSize(20).fillColor('#19A552').text(appName, { align: 'center' });
    doc.fontSize(16).fillColor('#111827').text('Payment receipt', {
      align: 'center',
    });
    doc.moveDown(0.4);
    doc
      .fontSize(10)
      .fillColor('#6b7280')
      .text(`Generated ${formatDate(new Date())}`, { align: 'center' });
    doc.moveDown(1);

    doc.fontSize(11).fillColor('#111827');
    const rows = [
      ['Booking ID', data.bookingId || '—'],
      ['Service', data.service || '—'],
      ['Provider', data.provider || '—'],
      ['Date', formatDate(data.date)],
      ['Patient', data.patient || '—'],
      ['Amount', rupees(data.amount, data.currency)],
      ['Payment status', data.paymentStatus || '—'],
      ['Payment method', data.paymentMethod || '—'],
      ['Transaction reference', data.paymentReference || '—'],
    ];
    rows.forEach(([label, value]) => {
      doc.font('Helvetica-Bold').text(`${label}: `, { continued: true });
      doc.font('Helvetica').text(String(value));
    });

    doc.moveDown(1.5);
    doc
      .fontSize(9)
      .fillColor('#6b7280')
      .text(
        'This receipt is for the healthcare service booked through the app. Keep it for your records. Card or UPI credentials are never stored on this document.',
      );

    doc.end();
  });
}

module.exports = { generateBookingReceiptPdf };
