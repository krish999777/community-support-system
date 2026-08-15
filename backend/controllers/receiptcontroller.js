const Donor = require('../models/donor');
const { generateReceiptPDF } = require('../utils/pdfgenerator');
const sendMail = require('../utils/mailservice');

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

    if (!fullName || !phone || !amount || !mode) {
      return res.status(400).json({ message: 'fullName, phone, amount, and mode are required' });
    }

    // 1. Strict Find: match donor by exact phone
    let donor = await Donor.findOne({ mobile: phone });

    if (!donor) {
      // Inline Registration logic: Create donor if not found but details are provided
      const { address, nearestRailwayStation, pan, aadhaar } = req.body;
      donor = new Donor({
        fullName,
        mobile: phone,
        email: email || '',
        address: address || '',
        nearestRailwayStation: nearestRailwayStation || '',
        pan: pan || '',
        aadhaar: aadhaar || ''
      });
      await donor.save();
    } else {
      // Opt: update email if missing
      if (email && !donor.email) donor.email = email;
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

    // 2. Generate PDF in-memory cleanly
    const donorForPDF = {
      ...donor.toObject(),
      fullName: fullName || donor.fullName,
    };

    // Background generation and email sequence
    generateReceiptPDF(donorForPDF, donationData)
      .then(pdfBuffer => {
         const recipientEmail = email || donor.email;
         if (recipientEmail) {
            sendMail(recipientEmail, pdfBuffer).catch(e => console.error('Email error:', e.message));
         }
      })
      .catch(e => console.error('PDF generation error:', e.message));

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
exports.downloadReceipt = async (req, res) => {
  try {
    const { receiptNo } = req.params;
    const donor = await Donor.findOne({ 'donations.receiptNo': receiptNo });
    if (!donor) return res.status(404).json({ message: 'Receipt not found' });

    const receipt = donor.donations.find(d => d.receiptNo === receiptNo);
    
    // Generate PDF natively
    const pdfBuffer = await generateReceiptPDF(donor, receipt);
    res.contentType('application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${receiptNo}.pdf"`);
    res.send(pdfBuffer);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};