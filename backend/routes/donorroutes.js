const express = require('express');
const router = express.Router();
const donorController = require('../controllers/donorcontroller');
const auth = require('../middleware/auth');
const requireAdmin = require('../middleware/requireAdmin');
const multer = require('multer');
const path = require('path');

const storage = multer.memoryStorage();
const upload = multer({ storage });

router.post('/add', auth, requireAdmin, upload.fields([{ name: 'panFile', maxCount: 1 }, { name: 'aadhaarFile', maxCount: 1 }]), donorController.adddonor);
router.get('/search/:query', auth, donorController.searchdonor);
router.get('/all', auth, requireAdmin, donorController.getAllDonors);
router.get('/profile/:mobile', auth, donorController.getDonorProfile);
router.put('/profile/:mobile', auth, requireAdmin, upload.fields([{ name: 'panFile', maxCount: 1 }, { name: 'aadhaarFile', maxCount: 1 }]), donorController.updateDonor);
router.delete('/profile/:mobile', auth, requireAdmin, donorController.deleteDonor);

module.exports = router;