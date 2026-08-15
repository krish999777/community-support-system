const express = require('express');
const router = express.Router();
const multer = require('multer');
const auth = require('../middleware/auth');
const requireAdmin = require('../middleware/requireAdmin');
const importController = require('../controllers/importcontroller');

const upload = multer({ dest: 'uploads/' });

router.post('/csv', auth, requireAdmin, upload.single('file'), importController.importCSV);

module.exports = router;   // ❗ not router()