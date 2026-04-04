const PDFDocument = require('pdfkit');
const fs = require('fs');

exports.generateReceiptPDF = (donor, donation, filePath) => {
  const doc = new PDFDocument({ margin: 50 });
  doc.pipe(fs.createWriteStream(filePath));

  // Header
  doc.fontSize(22).font('Helvetica-Bold').text('Babariyawad Social Community', { align: 'center' });
  doc.fontSize(11).font('Helvetica').text('Official Donation Receipt', { align: 'center' });
  doc.moveDown(0.5);
  doc.moveTo(50, doc.y).lineTo(560, doc.y).stroke();
  doc.moveDown();

  // Receipt & Date
  doc.fontSize(12).font('Helvetica-Bold').text(`Receipt No: `, { continued: true }).font('Helvetica').text(donation.receiptNo);
  doc.font('Helvetica-Bold').text(`Date: `, { continued: true }).font('Helvetica').text(
    donation.date ? new Date(donation.date).toLocaleDateString('en-IN') : new Date().toLocaleDateString('en-IN')
  );
  doc.moveDown();

  // Donor Details
  doc.font('Helvetica-Bold').fontSize(13).text('Donor Information');
  doc.moveTo(50, doc.y).lineTo(560, doc.y).stroke();
  doc.moveDown(0.3);
  const details = [
    ['Full Name', donor.fullName || '-'],
    ['Email', donation.email || donor.email || '-'],
    ['Phone', donation.phone || donor.mobile || '-'],
    ['PAN Number', donor.pan || '-'],
    ['Aadhaar Number', donor.aadhaar || '-'],
    ['Address', donor.address || '-'],
  ];
  details.forEach(([label, value]) => {
    doc.font('Helvetica-Bold').fontSize(11).text(`${label}: `, { continued: true }).font('Helvetica').text(value);
  });

  doc.moveDown();

  // Donation Details
  doc.font('Helvetica-Bold').fontSize(13).text('Donation Details');
  doc.moveTo(50, doc.y).lineTo(560, doc.y).stroke();
  doc.moveDown(0.3);
  const donationDetails = [
    ['Amount', `Rs. ${donation.amount}/-`],
    ['Payment Mode', donation.mode || '-'],
    ['Purpose', donation.purpose || '-'],
  ];
  donationDetails.forEach(([label, value]) => {
    doc.font('Helvetica-Bold').fontSize(11).text(`${label}: `, { continued: true }).font('Helvetica').text(value);
  });

  doc.moveDown(2);
  doc.moveTo(50, doc.y).lineTo(560, doc.y).stroke();
  doc.moveDown(0.5);
  doc.fontSize(10).text('This is a computer-generated receipt. No signature required.', { align: 'center' });
  doc.fontSize(10).text('Thank you for your generous donation.', { align: 'center' });

  doc.end();
};