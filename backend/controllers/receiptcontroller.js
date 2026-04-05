const Donor = require('../models/donor');
const { generateReceiptPDF } = require('../utils/pdfgenerator');
const sendMail = require('../utils/mailservice');
const path = require('path');
const fs = require('fs');

/**
 * POST /api/receipt/donate
 * Body: { fullName, email, phone, amount, mode, purpose, date, pan?, aadhaar?, address? }
 *
 * Flow:
 *  1. Try to find existing donor by email or name
 *  2. If not found → create a minimal donor record
 *  3. Push donation, generate PDF, send email
 */
exports.addDonation = async (req, res) => {
  try {
    const { fullName, email, phone, amount, mode, purpose, date, transactionId, chequeNumber, accountNumber, ifsc } = req.body;

    if (!fullName || !email || !amount || !mode) {
      return res.status(400).json({ message: 'fullName, email, amount, and mode are required' });
    }

    // 1. Strict Find: match donor by exact email
    let donor = await Donor.findOne({ email: { $regex: `^${email}$`, $options: 'i' } });

    if (!donor) {
      return res.status(404).json({ message: 'Donor not registered in database. Please register them first.' });
    } else {
      // Opt: update phone if missing
      if (phone && !donor.mobile) donor.mobile = phone;
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
      transactionId: transactionId || '',
      chequeNumber: chequeNumber || '',
      accountNumber: accountNumber || '',
      ifsc: ifsc || ''
    };

    donor.donations.push(donationData);
    await donor.save();

    // 2. Generate PDF
    const receiptsDir = path.join(__dirname, '../receipts');
    if (!fs.existsSync(receiptsDir)) fs.mkdirSync(receiptsDir, { recursive: true });
    const filePath = path.join(receiptsDir, `${receiptNo}.pdf`);

    // Use donor details directly for the PDF
    const donorForPDF = {
      ...donor.toObject(),
      fullName: fullName || donor.fullName,
    };

    generateReceiptPDF(donorForPDF, donationData, filePath);

    // 3. Send email (non-blocking)
    const recipientEmail = email || donor.email;
    if (recipientEmail) {
      setTimeout(async () => {
        try { await sendMail(recipientEmail, filePath); }
        catch (e) { console.error('Email send failed:', e.message); }
      }, 1800);
    }

    res.json({
      message: 'Donation recorded, invoice generated',
      receiptNo,
      donorId: donor._id,
    });

  } catch (err) {
    console.error(err);
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

// Get receipt details by receipt number
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

// Download receipt PDF
exports.downloadReceipt = (req, res) => {
  const { receiptNo } = req.params;
  const filePath = path.join(__dirname, `../receipts/${receiptNo}.pdf`);
  if (fs.existsSync(filePath)) {
    res.download(filePath);
  } else {
    res.status(404).json({ message: 'Receipt PDF not found. It may still be generating — try again in a moment.' });
  }
};