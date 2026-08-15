const nodemailer = require('nodemailer');

const sendMail = async (to, pdfBuffer) => {
  const transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: process.env.EMAIL_PORT,
    secure: process.env.EMAIL_PORT == 465, // true for 465, false for other ports
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });

  await transporter.sendMail({
    from: `Babariyawad Social Community <${process.env.EMAIL_FROM || process.env.EMAIL_USER}>`,
    to,
    subject: 'Donation Receipt',
    text: 'Thank you for your generous donation. Please find your official receipt attached.',
    attachments: [{ filename: 'Donation_Receipt.pdf', content: pdfBuffer }]
  });
};

module.exports = sendMail;