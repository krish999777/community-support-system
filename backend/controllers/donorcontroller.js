const Donor = require('../models/donor');

exports.adddonor = async (req, res) => {
  try {
    const { mobile } = req.body;
    if (!mobile) {
      return res.status(400).json({ message: 'Phone Number is required.' });
    }
    
    // Check missing donor phone
    const existingDonor = await Donor.findOne({ mobile });
    if (existingDonor) {
      return res.status(400).json({ message: 'A donor with this Phone Number already exists.' });
    }

    const donorData = { ...req.body };
    if (req.files) {
      if (req.files.panFile && req.files.panFile[0]) {
        donorData.panFile = {
            data: req.files.panFile[0].buffer,
            contentType: req.files.panFile[0].mimetype
        };
      }
      if (req.files.aadhaarFile && req.files.aadhaarFile[0]) {
        donorData.aadhaarFile = {
            data: req.files.aadhaarFile[0].buffer,
            contentType: req.files.aadhaarFile[0].mimetype
        };
      }
    }

    const newDonor = await Donor.create(donorData);
    res.json(newDonor);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.searchdonor = async (req, res) => {
  try {
    const { query } = req.params;

    const donor = await Donor.findOne({ mobile: query });

    res.json(donor);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};