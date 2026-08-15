const mongoose = require('mongoose');

const donationSchema = new mongoose.Schema({
  amount: Number,
  mode: String,
  date: Date,
  receiptNo: String,
  purpose: String,
  phone: String,
  email: String,
  transactionId: String,
  chequeNumber: String,
  accountNumber: String,
  ifsc: String,
});

const donorSchema = new mongoose.Schema({
  fullName: String,
  mobile: String,
  email: String,
  address: String,
  nearestRailwayStation: String,
  pan: String,
  aadhaar: String,
  panFile: { data: Buffer, contentType: String },
  aadhaarFile: { data: Buffer, contentType: String },
  donations: [donationSchema]
});

module.exports = mongoose.model('donor', donorSchema);