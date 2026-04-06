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

    const donor = await Donor.findOne({ mobile: query }).select('-panFile -aadhaarFile');

    res.json(donor);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getDonorProfile = async (req, res) => {
  try {
    const { mobile } = req.params;
    const donor = await Donor.findOne({ mobile });
    if (!donor) return res.status(404).json({ message: 'Donor not found' });

    const donorObj = donor.toObject();

    // Convert BSON binary data to Base64 for safe HTML transfer
    if (donorObj.panFile && donorObj.panFile.data) {
      const b64 = donorObj.panFile.data.toString('base64');
      donorObj.panFile.base64 = `data:${donorObj.panFile.contentType};base64,${b64}`;
      delete donorObj.panFile.data; // Don't send the heavy buffer array over JSON
    }

    if (donorObj.aadhaarFile && donorObj.aadhaarFile.data) {
      const b64 = donorObj.aadhaarFile.data.toString('base64');
      donorObj.aadhaarFile.base64 = `data:${donorObj.aadhaarFile.contentType};base64,${b64}`;
      delete donorObj.aadhaarFile.data;
    }

    res.json(donorObj);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};