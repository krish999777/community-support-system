const jwt = require('jsonwebtoken');

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