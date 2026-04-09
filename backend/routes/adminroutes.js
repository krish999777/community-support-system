const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admincontroller');
const auth = require('../middleware/auth');

router.post('/register', adminController.registerAdmin);
router.post('/login', adminController.loginAdmin);
router.get('/stats', auth, adminController.getDashboardStats);
router.get('/export', auth, adminController.exportDonationsCSV);

module.exports = router;