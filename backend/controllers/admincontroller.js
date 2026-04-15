const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Donor = require('../models/donor');
const AuthPin = require('../models/AuthPin');

// Initial administrator bootstrap: Use this to log in if no PINs exist in the DB.
const BOOTSTRAP_PIN = '5173'; 

exports.loginWithPin = async (req, res) => {
  const { pin } = req.body;

  try {
    // 1. Permanent Root Access: The master bootstrap PIN is always active
    if (pin === BOOTSTRAP_PIN) {
      const token = jwt.sign(
        { id: 'root', label: 'Primary Admin', role: 'admin' }, 
        'secretkey', 
        { expiresIn: '8h' }
      );
      return res.json({ token, username: 'Primary Admin', role: 'admin' });
    }

    const pinCount = await AuthPin.countDocuments();
    if (pinCount === 0) {
      return res.status(401).json({ message: 'Setup Required: Please use the master PIN to create your first access code.' });
    }

    const allPins = await AuthPin.find({});
    let matchingPin = null;

    for (const p of allPins) {
      const isMatch = await bcrypt.compare(pin, p.pin);
      if (isMatch) {
        matchingPin = p;
        break;
      }
    }

    if (!matchingPin) {
      return res.status(401).json({ message: 'Invalid Access PIN' });
    }

    const token = jwt.sign(
      { id: matchingPin._id, label: matchingPin.label, role: matchingPin.role }, 
      'secretkey', 
      { expiresIn: '8h' }
    );
    res.json({ token, username: matchingPin.label, role: matchingPin.role });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getPins = async (req, res) => {
  try {
    const pins = await AuthPin.find({}, '-pin'); // Exclude hash
    res.json(pins);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.createPin = async (req, res) => {
  const { pin, label, role } = req.body;
  
  if (!/^\d{4}$/.test(pin)) {
    return res.status(400).json({ message: 'PIN must be exactly 4 digits' });
  }

  try {
    const hashedPin = await bcrypt.hash(pin, 10);
    const newPin = new AuthPin({ pin: hashedPin, label, role });
    await newPin.save();
    res.status(201).json({ message: 'Access PIN created' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.deletePin = async (req, res) => {
  try {
    await AuthPin.findByIdAndDelete(req.params.id);
    res.json({ message: 'PIN deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getDashboardStats = async (req, res) => {
  try {
    const donors = await Donor.find({});
    
    let totalAmount = 0;
    let totalDonorsRegistered = donors.length;
    let uniqueDonorsCount = 0;
    
    const monthlyStatsMap = {}; // Key: "Month Year"
    const paymentModeMap = {};
    const purposeMap = {};

    donors.forEach(donor => {
      if (donor.donations && donor.donations.length > 0) {
        uniqueDonorsCount++;
        donor.donations.forEach(d => {
          totalAmount += Number(d.amount);
          
          // Monthly breakdown
          const date = new Date(d.date);
          const monthYear = date.toLocaleString('default', { month: 'long', year: 'numeric' });
          if (!monthlyStatsMap[monthYear]) {
            monthlyStatsMap[monthYear] = { month: monthYear, amount: 0, count: 0, sortKey: date.getTime() };
          }
          monthlyStatsMap[monthYear].amount += Number(d.amount);
          monthlyStatsMap[monthYear].count += 1;

          // Payment Mode
          const mode = d.mode || 'Unknown';
          paymentModeMap[mode] = (paymentModeMap[mode] || 0) + Number(d.amount);

          // Purpose
          const purpose = d.purpose || 'General';
          purposeMap[purpose] = (purposeMap[purpose] || 0) + Number(d.amount);
        });
      }
    });

    const monthlyStats = Object.values(monthlyStatsMap).sort((a, b) => b.sortKey - a.sortKey);
    const paymentModes = Object.entries(paymentModeMap).map(([name, amount]) => ({ name, amount }));
    const purposes = Object.entries(purposeMap).map(([name, amount]) => ({ name, amount }));

    res.json({
      totalAmount,
      totalDonorsRegistered,
      totalDonorsDonated: uniqueDonorsCount,
      monthlyStats,
      paymentModes,
      purposes
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.exportDonationsCSV = async (req, res) => {
  try {
    const donors = await Donor.find({});
    let csv = 'Receipt No,Date,Donor Name,Mobile,Email,PAN,Aadhaar,Address,Amount,Purpose,Mode,Reference Details\n';

    donors.forEach(donor => {
      if (donor.donations && donor.donations.length > 0) {
        donor.donations.forEach(d => {
          const dateStr = new Date(d.date).toLocaleDateString();
          const refDetails = d.transactionId || d.chequeNumber || '-';
          const row = [
            d.receiptNo,
            dateStr,
            `"${donor.fullName}"`,
            donor.mobile,
            donor.email || 'N/A',
            donor.pan || 'N/A',
            donor.aadhaar || 'N/A',
            `"${donor.address || ''}"`,
            d.amount,
            `"${d.purpose || 'General'}"`,
            d.mode,
            `"${refDetails}"`
          ];
          csv += row.join(',') + '\n';
        });
      }
    });

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=bsc_donations_export.csv');
    res.status(200).send(csv);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};