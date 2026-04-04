const express = require('express');
const router = express.Router();
const receiptController = require('../controllers/receiptcontroller');

router.post('/donate', receiptController.addDonation);
router.get('/history/:donorId', receiptController.getDonationHistory);
router.get('/receipt/:receiptNo', receiptController.getReceiptByNumber);
router.get('/download/:receiptNo', receiptController.downloadReceipt);
module.exports = router;