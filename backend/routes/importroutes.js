const express = require('express');
const router = express.Router();
const multer = require('multer');
const auth = require('../middleware/auth');
const importController = require('../controllers/importcontroller');

const upload = multer({ dest: 'uploads/' });

router.post('/csv', auth, upload.single('file'), importController.importCSV);

module.exports = router;   // ❗ not router()