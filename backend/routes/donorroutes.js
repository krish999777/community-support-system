const express = require('express');
const router = express.Router();
const donorController = require('../controllers/donorcontroller');
const auth = require('../middleware/auth');
const multer = require('multer');
const path = require('path');

const storage = multer.memoryStorage();
const upload = multer({ storage });

router.post('/add', auth, upload.fields([{ name: 'panFile', maxCount: 1 }, { name: 'aadhaarFile', maxCount: 1 }]), donorController.adddonor);
router.get('/search/:query', auth, donorController.searchdonor);

module.exports = router;