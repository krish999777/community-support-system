const Donor = require('../models/donor');

exports.adddonor = async (req, res) => {
  try {
    const newDonor = await Donor.create(req.body);
    res.json(newDonor);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.searchdonor = async (req, res) => {
  try {
    const { query } = req.params;

    const donor = await Donor.findOne({
      $or: [
        { fullName: { $regex: query, $options: 'i' } },
        { mobile: query },
        { pan: query },
        { email: { $regex: query, $options: 'i' } }
      ]
    });

    res.json(donor);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};