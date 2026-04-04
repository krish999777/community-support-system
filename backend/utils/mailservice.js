const nodemailer = require('nodemailer');

const sendMail = async (to, filePath) => {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL,
      pass: process.env.PASS
    }
  });

  await transporter.sendMail({
    from: process.env.EMAIL,
    to,
    subject: 'Donation Receipt',
    text: 'Thank you for your donation.',
    attachments: [{ path: filePath }]
  });
};

module.exports = sendMail;