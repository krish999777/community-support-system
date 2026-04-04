const Donor = require('../models/donor');
const { generateReceiptPDF } = require('../utils/pdfgenerator');
const sendMail = require('../utils/mailservice');
const path = require('path');
const fs = require('fs');

exports.addDonation = async (req, res) => {
  try {
    const { donorId, amount, mode, purpose, date, phone, email } = req.body;

    const donor = await Donor.findById(donorId);
    if (!donor) {
      return res.status(404).json({ message: 'Donor not found' });
    }

    const receiptNo = 'RCPT-' + Date.now();

    const donationData = {
      amount,
      mode,
      date: date ? new Date(date) : new Date(),
      receiptNo,
      purpose: purpose || '',
      phone: phone || donor.mobile || '',
      email: email || donor.email || '',
    };

    donor.donations.push(donationData);
    await donor.save();

    // Generate PDF
    const receiptsDir = path.join(__dirname, '../receipts');
    if (!fs.existsSync(receiptsDir)) fs.mkdirSync(receiptsDir, { recursive: true });
    const filePath = path.join(receiptsDir, `${receiptNo}.pdf`);
    generateReceiptPDF(donor, donationData, filePath);

    // Send email (non-blocking — don't crash if it fails)
    const recipientEmail = email || donor.email;
    if (recipientEmail) {
      setTimeout(async () => {
        try {
          await sendMail(recipientEmail, filePath);
        } catch (e) {
          console.error('Email send failed:', e.message);
        }
      }, 1500); // give PDF time to finish writing
    }

    res.json({ message: 'Donation added, PDF generated', receiptNo });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get all donations of a donor
exports.getDonationHistory = async (req, res) => {
  try {
    const { donorId } = req.params;
    const donor = await Donor.findById(donorId);
    if (!donor) return res.status(404).json({ message: 'Donor not found' });
    res.json(donor.donations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get single receipt details using receipt number
exports.getReceiptByNumber = async (req, res) => {
  try {
    const { receiptNo } = req.params;
    const donor = await Donor.findOne({ 'donations.receiptNo': receiptNo });
    if (!donor) return res.status(404).json({ message: 'Receipt not found' });

    const receipt = donor.donations.find(d => d.receiptNo === receiptNo);
    res.json({
      donorName: donor.fullName,
      mobile: donor.mobile,
      pan: donor.pan,
      aadhaar: donor.aadhaar,
      email: donor.email,
      address: donor.address,
      receipt
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.downloadReceipt = (req, res) => {
  const { receiptNo } = req.params;
  const filePath = path.join(__dirname, `../receipts/${receiptNo}.pdf`);
  if (fs.existsSync(filePath)) {
    res.download(filePath);
  } else {
    res.status(404).json({ message: 'Receipt PDF not found' });
  }
};