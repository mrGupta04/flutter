const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const { v4: uuidv4 } = require('uuid');

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

function writeSectionTitle(doc, title) {
  doc.moveDown(0.5);
  doc.fontSize(12).fillColor('#208376').text(title, { underline: true });
  doc.moveDown(0.25);
  doc.fillColor('#111827');
}

function generatePrescriptionPdf({
  prescription,
  doctorName,
  doctorQualification,
  clinicName,
  slotStart,
}) {
  ensureUploadsDir();

  const fileName = `prescription-${prescription.id || uuidv4()}.pdf`;
  const filePath = path.join(uploadsDir, fileName);
  const appName = process.env.APP_NAME || 'MedConnect';

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

    doc.fontSize(20).fillColor('#208376').text(appName, { align: 'center' });
    doc.fontSize(16).fillColor('#111827').text('Medical Prescription', {
      align: 'center',
    });
    doc.moveDown(0.5);
    doc
      .fontSize(10)
      .fillColor('#6b7280')
      .text(`Issued on ${formatDate(new Date())}`, { align: 'center' });
    doc.moveDown(1);

    doc.fontSize(11).fillColor('#111827');
    doc.text(`Doctor: Dr. ${doctorName || 'Doctor'}`);
    if (doctorQualification) {
      doc.text(`Qualification: ${doctorQualification}`);
    }
    if (clinicName) {
      doc.text(`Clinic: ${clinicName}`);
    }
    if (slotStart) {
      doc.text(`Consultation: ${formatDate(slotStart)}`);
    }

    writeSectionTitle(doc, 'Patient details');
    doc.fontSize(11).text(`Name: ${prescription.patientName || '—'}`);
    if (prescription.symptoms) {
      doc.moveDown(0.25);
      doc.text('Symptoms / reason:');
      doc.fontSize(10).fillColor('#374151').text(prescription.symptoms);
      doc.fillColor('#111827').fontSize(11);
    }

    if (prescription.diagnosis) {
      writeSectionTitle(doc, 'Diagnosis');
      doc.fontSize(11).text(prescription.diagnosis);
    }

    const medicines = prescription.medicines || [];
    if (medicines.length > 0) {
      writeSectionTitle(doc, 'Medicines');
      medicines.forEach((med, index) => {
        doc.fontSize(11).text(`${index + 1}. ${med.name}`);
        const details = [
          med.dosage ? `Dosage: ${med.dosage}` : null,
          med.frequency ? `Frequency: ${med.frequency}` : null,
          med.duration ? `Duration: ${med.duration}` : null,
        ]
          .filter(Boolean)
          .join(' | ');
        if (details) {
          doc.fontSize(10).fillColor('#374151').text(details);
          doc.fillColor('#111827').fontSize(11);
        }
        if (med.instructions) {
          doc.fontSize(10).fillColor('#374151').text(`Note: ${med.instructions}`);
          doc.fillColor('#111827').fontSize(11);
        }
        doc.moveDown(0.25);
      });
    }

    const tests = prescription.tests || [];
    if (tests.length > 0) {
      writeSectionTitle(doc, 'Tests / investigations');
      tests.forEach((test, index) => {
        doc.fontSize(11).text(`${index + 1}. ${test.name}`);
        if (test.notes) {
          doc.fontSize(10).fillColor('#374151').text(test.notes);
          doc.fillColor('#111827').fontSize(11);
        }
        doc.moveDown(0.25);
      });
    }

    if (prescription.advice) {
      writeSectionTitle(doc, 'Advice');
      doc.fontSize(11).text(prescription.advice);
    }

    doc.moveDown(2);
    doc
      .fontSize(10)
      .fillColor('#6b7280')
      .text(
        'This prescription is generated electronically after an online consultation. Please follow your doctor\'s advice and consult again if symptoms persist.',
        { align: 'left' },
      );

    doc.end();
  });
}

module.exports = {
  generatePrescriptionPdf,
};
