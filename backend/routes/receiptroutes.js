const express = require('express');
const router = express.Router();
const receiptController = require('../controllers/receiptcontroller');
const auth = require('../middleware/auth');

router.post('/donate', auth, receiptController.addDonation);
router.get('/history/:donorId', auth, receiptController.getDonationHistory);
router.get('/receipt/:receiptNo', auth, receiptController.getReceiptByNumber);
router.get('/download/:receiptNo', auth, receiptController.downloadReceipt);
module.exports = router;