const jwt = require('jsonwebtoken');

// Suppose your admin/user object
const admin = {
  id: '123456',
  username: 'rishik'
};

// Generate token
const token = jwt.sign(
  { id: admin.id, username: admin.username }, // payload
  'secretkey',                               // must match middleware
  { expiresIn: '1h' }                        // optional expiry
);

console.log(token);