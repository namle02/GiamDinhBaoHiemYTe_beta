const express = require('express');
const router = express.Router();
const BenhNhanLoiMaMayController = require('../Controllers/BenhNhanLoiMaMayController');

// Lấy danh sách bệnh nhân lỗi mã máy
router.get('/', BenhNhanLoiMaMayController.getDsBenhNhanLoiMaMay);

// Lưu danh sách bệnh nhân lỗi mã máy (từ WPF)
router.post('/', BenhNhanLoiMaMayController.saveDsBenhNhanLoiMaMay);

module.exports = router;
