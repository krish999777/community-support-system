const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const connectDB = require('../config/db');   // ✅ CORRECT

const app = express();

// ✅ Middleware FIRST
app.use(cors());
app.use(express.json());

// ✅ Connect MongoDB
connectDB();

// ✅ API Routes FIRST (correct paths)
app.use('/api/donor', require('../routes/donorroutes'));
app.use('/api/receipt', require('../routes/receiptroutes'));
app.use('/api/admin', require('../routes/adminroutes'));
app.use('/api/import', require('../routes/importroutes'));

// ================= SERVE FRONTEND =================
const fs = require('fs');

// React build copied by Docker to backend/public, or committed in doner_receipt_app/public
let frontendPath = path.join(__dirname, '../public');
if (!fs.existsSync(path.join(frontendPath, 'index.html'))) {
  frontendPath = path.join(__dirname, './public');
}

app.use(express.static(frontendPath));

// For any non-API route, serve React index.html
app.use((req, res) => {
  if (req.originalUrl.startsWith('/api')) {
    return res.status(404).json({ message: 'API route not found' });
  }
  res.sendFile(path.join(frontendPath, 'index.html'));
});

// ==================================================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});