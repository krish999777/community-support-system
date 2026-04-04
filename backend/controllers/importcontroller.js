const fs = require('fs');
const csv = require('csv-parser');
const Donor = require('../models/donor');

exports.importCSV = (req, res) => {
  const results = [];

  fs.createReadStream(req.file.path)
    .pipe(csv())
    .on('data', (data) => results.push(data))
    .on('end', async () => {
      for (let row of results) {
        await Donor.create({
          fullname: row['Full Name'],
          mobile: row['Mobile Number'],
          email: row['Email'],
          address: row['Address'],
          pan: row['PAN Number'],
          aadhaar: row['Aadhaar Number']
        });
      }

      res.json({ message: 'CSV data imported successfully' });
    });
};