const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

function convertNumberToWords(amount) {
    amount = Math.round(Number(amount));
    if (amount === 0) return "Zero";
    const single = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"];
    const double = ["Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    const tens = ["", "Ten", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
    
    function formatTens(num) {
        if (num < 10) return single[num];
        if (num < 20) return double[num - 10];
        return tens[Math.floor(num / 10)] + (num % 10 !== 0 ? " " + single[num % 10] : "");
    }
    
    function convert(n) {
        let str = "";
        if (n > 99) {
            str += single[Math.floor(n / 100)] + " Hundred ";
            n %= 100;
        }
        if (n > 0) str += formatTens(n) + " ";
        return str.trim();
    }
    
    let words = "";
    if (amount >= 10000000) { words += convert(Math.floor(amount / 10000000)) + " Crore "; amount %= 10000000; }
    if (amount >= 100000) { words += convert(Math.floor(amount / 100000)) + " Lakh "; amount %= 100000; }
    if (amount >= 1000) { words += convert(Math.floor(amount / 1000)) + " Thousand "; amount %= 1000; }
    if (amount > 0) { words += convert(amount); }
    return words.trim();
}

exports.generateReceiptPDF = (donor, donation) => {
  return new Promise((resolve, reject) => {
    // Standard A4 Size
    const doc = new PDFDocument({ size: 'A4', margin: 0 });
    const buffers = [];
    doc.on('data', buffers.push.bind(buffers));
    doc.on('end', () => resolve(Buffer.concat(buffers)));
    doc.on('error', reject);

    const pageWidth = doc.page.width;
    const pageHeight = doc.page.height;

    // Background Canvas Fill (Soft Warm Off-White/Cream)
    doc.rect(0, 0, pageWidth, pageHeight).fill('#FBF9F6');

    // Ornate Border Layout
    const goldColor = '#CAA672';
    
    // Outer Thick Border
    doc.roundedRect(25, 25, pageWidth - 50, pageHeight - 50, 15)
       .lineWidth(2)
       .stroke(goldColor);
       
    // Inner Thin Border
    doc.roundedRect(32, 32, pageWidth - 64, pageHeight - 64, 12)
       .lineWidth(0.5)
       .stroke(goldColor);

    // Corner Ornaments (Simple Gold Circles)
    doc.circle(32, 32, 3).fillAndStroke('#FFF', goldColor);
    doc.circle(pageWidth - 32, 32, 3).fillAndStroke('#FFF', goldColor);
    doc.circle(32, pageHeight - 32, 3).fillAndStroke('#FFF', goldColor);
    doc.circle(pageWidth - 32, pageHeight - 32, 3).fillAndStroke('#FFF', goldColor);

    // Branding Logo
    const logoPath = path.join(__dirname, '../../frontend/public/WhatsApp Image 2026-04-09 at 14.10.43.jpeg');
    let startY = 60;
    if (fs.existsSync(logoPath)) {
        doc.image(logoPath, (pageWidth - 90) / 2, startY, { fit: [90, 90] });
        startY += 95;
    }

    // Classic Certificate Title (Times-Roman)
    doc.font('Times-Roman')
       .fontSize(22)
       .fillColor('#222222')
       .text('Samastha Darji Samaj Babariyawad, Mumbai', 0, startY, { align: 'center', width: pageWidth });
    
    startY += 35;

    // Samaj Details
    doc.font('Helvetica')
       .fontSize(10)
       .fillColor('#555555')
       .text('Office address - 8, Hirvi Chawl, Sane Guruji Marg, Tardeo, Mumbai 400034', 0, startY, { align: 'center', width: pageWidth });
    startY += 15;
    doc.text('Samaj PAN : AAGTS1081B', 0, startY, { align: 'center', width: pageWidth });
    startY += 25;

    // Elegant Divider Center Ornament
    const cX = pageWidth / 2;
    doc.moveTo(100, startY)
       .lineTo(cX - 25, startY)
       .lineWidth(0.7)
       .strokeColor(goldColor)
       .stroke();
       
    // center infinity/diamond loop
    doc.circle(cX, startY, 4).lineWidth(1).strokeColor(goldColor).stroke();
    doc.circle(cX - 10, startY, 2).lineWidth(1).fillAndStroke('#FFF', goldColor);
    doc.circle(cX + 10, startY, 2).lineWidth(1).fillAndStroke('#FFF', goldColor);
    // tiny flares
    doc.moveTo(cX - 20, startY).lineTo(cX - 14, startY).lineWidth(1).stroke(goldColor);
    doc.moveTo(cX + 20, startY).lineTo(cX + 14, startY).lineWidth(1).stroke(goldColor);

    doc.moveTo(cX + 25, startY)
       .lineTo(pageWidth - 100, startY)
       .lineWidth(0.7)
       .strokeColor(goldColor)
       .stroke();

    startY += 30;

    // Subtitle
    doc.font('Times-Roman')
       .fontSize(16)
       .fillColor('#333333')
       .text('DONATION RECEIPT', 0, startY, { align: 'center', width: pageWidth });
    
    startY += 35;

    // Aggregate Fields to Print
    const refDate = donation.date ? new Date(donation.date) : new Date();
    const formattedDate = refDate.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

    const items = [
        ['Receipt No.', donation.receiptNo || '-'],
        ['Date', formattedDate],
        ['Donor Name', donor.fullName || '-'],
        ['Email', donation.email || donor.email || 'N/A'],
        ['Phone', donation.phone || donor.mobile || '-'],
        ['Address', donor.address || '-'],
        ['Donor PAN ID', donor.pan || '-'],
        ['Aadhaar', donor.aadhaar || '-'],
        ['Nature of Donation', donation.purpose || 'General'],
        ['Payment Mode', donation.mode || '-'],
    ];

    if (donation.mode === 'UPI' || donation.mode === 'NEFT') {
        items.push(['Transaction ID', donation.transactionId || '-']);
    } else if (donation.mode === 'Cheque') {
        items.push(['Cheque Number', donation.chequeNumber || '-']);
        items.push(['Account Number', donation.accountNumber || '-']);
        items.push(['IFSC Code', donation.ifsc || '-']);
    }

    const colLeft = 80;
    const colRight = 240;

    // Sequential Print Algorithm
    items.forEach(item => {
        // Label Side
        doc.font('Helvetica').fontSize(12).fillColor('#555555').text(item[0], colLeft, startY);
        // Value Side
        doc.font('Helvetica-Bold').fontSize(12).fillColor('#222222').text(item[1], colRight, startY, {
            width: pageWidth - colRight - 80,
            align: 'left'
        });
        
        // Slightly dynamically space out based on text height
        const heightAssumed = doc.heightOfString(item[1], { width: pageWidth - colRight - 80 });
        startY += (heightAssumed > 14) ? heightAssumed + 15 : 30;
    });

    startY += 12;

    // Divider Bottom
    doc.moveTo(100, startY)
       .lineTo(pageWidth - 100, startY)
       .lineWidth(0.5)
       .strokeColor(goldColor)
       .stroke();
    
    startY += 30;

    // Monetary Calculation Floor
    const formattedAmount = Number(donation.amount).toLocaleString('en-IN');
    doc.font('Helvetica-Bold')
       .fontSize(16)
       .fillColor('#1F4A38') // Dark Elegant Forest Green
       .text('Amount Received', colLeft, startY);
    
    doc.text('Rs.' + formattedAmount, colLeft, startY, { align: 'right', width: pageWidth - colLeft - 80 });

    startY += 25;

    // Verbose Word Conversion
    const wordAmount = convertNumberToWords(donation.amount);
    doc.font('Helvetica-Oblique')
       .fontSize(11)
       .fillColor('#666666')
       .text(`(Rupees ${wordAmount} Only)`, colLeft, startY);

    // Fine Print Footer (Dynamic Y to prevent overlap)
    const footerY = Math.max(startY + 40, pageHeight - 85);
    doc.font('Helvetica')
       .fontSize(10)
       .fillColor('#A09F9C')
       .text('Computer generated receipt. Thank you for your donation.', 0, footerY, { align: 'center', width: pageWidth });

    doc.end();
  });
};