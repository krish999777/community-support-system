const express = require('express');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('../config/db');   // ✅ correct path

const app = express();

//  Connect MongoDB first
connectDB();

//  Middleware
app.use(cors());
app.use(express.json());

//  Routes
app.use('/api/donor', require('../routes/donorroutes'));
app.use('/api/receipt', require('../routes/receiptroutes'));
app.use('/api/admin', require('../routes/adminroutes'));
app.use('/api/import', require('../routes/importroutes'));
//  Test route (very useful to check server)
app.get('/', (req, res) => {
  res.send('API is running...');
});

// Start server
const port = process.env.PORT || 5000;
app.listen(port, () => {
  console.log(`Running on port ${port}`);
});