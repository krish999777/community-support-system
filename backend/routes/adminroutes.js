const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admincontroller');
const auth = require('../middleware/auth');
const requireAdmin = require('../middleware/requireAdmin');

router.post('/login-pin', adminController.loginWithPin);
router.get('/pins', auth, requireAdmin, adminController.getPins);
router.post('/pins', auth, requireAdmin, adminController.createPin);
router.delete('/pins/:id', auth, requireAdmin, adminController.deletePin);
router.get('/stats', auth, requireAdmin, adminController.getDashboardStats);
router.get('/export', auth, requireAdmin, adminController.exportDonationsCSV);

module.exports = router;