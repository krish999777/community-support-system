const express = require('express');
const router = express.Router();
const donorController = require('../controllers/donorcontroller');
const auth = require('../middleware/auth');

router.post('/add', auth, donorController.adddonor);
router.get('/search/:query', auth, donorController.searchdonor);

module.exports = router;