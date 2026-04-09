const jwt = require('jsonwebtoken');
const Donor = require('../models/donor');

const ADMINS = [
  { username: 'admin1', password: 'admin1_pass_13579' },
  { username: 'admin2', password: 'admin2_pass_98765' },
  { username: 'admin3', password: 'admin3_pass_43210' },
];

exports.registerAdmin = async (req, res) => {
  res.status(403).json({ message: 'Registration is disabled. Use a pre-configured admin account.' });
};

exports.loginAdmin = async (req, res) => {
  const { username, password } = req.body;

  const admin = ADMINS.find(a => a.username === username && a.password === password);
  if (!admin) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }

  const token = jwt.sign({ username: admin.username }, 'secretkey', { expiresIn: '8h' });
  res.json({ token, username: admin.username });
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