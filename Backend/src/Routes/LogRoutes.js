const express = require('express');
const router = express.Router();
const LogController = require('../Controllers/LogController');

// Middleware để log tất cả requests
const LogService = require('../Services/LogService');

// Routes cho quản lý logs
router.get('/', LogController.getLogs);
router.get('/stats', LogController.getLogStats);
router.get('/request/:requestId', LogController.getLogsByRequestId);
router.get('/service/:service', LogController.getLogsByService);
router.post('/clean', LogController.cleanOldLogs);
router.post('/create', LogController.createLog);

module.exports = router;
