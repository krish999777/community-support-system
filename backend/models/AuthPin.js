const mongoose = require('mongoose');

const authPinSchema = new mongoose.Schema({
  pin: { type: String, required: true },
  label: { type: String, required: true },
  role: { type: String, enum: ['admin', 'operator'], default: 'admin' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('AuthPin', authPinSchema);
