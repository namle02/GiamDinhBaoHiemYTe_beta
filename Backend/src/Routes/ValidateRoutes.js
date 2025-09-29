const express = require('express');
const router = express.Router();
const ValidateController = require('../Controllers/ValidateController');

// Các route liên quan đến validation

// Validate dữ liệu bệnh nhân với tất cả rule
router.post('/patient', ValidateController.validatePatient);

// Lấy danh sách tất cả rule
router.get('/rules', ValidateController.getRules);

// Lấy thông tin chi tiết của một rule theo tên
router.get('/rules/:ruleName', ValidateController.getRuleInfo);

// Bật/tắt một rule theo tên
router.put('/rules/:ruleName/toggle', ValidateController.toggleRule);

// Reload lại tất cả rule từ thư mục
router.post('/rules/reload', ValidateController.reloadRules);

// Validate dữ liệu với một rule cụ thể
router.post('/rules/:ruleName/validate', ValidateController.validateWithRule);

// Validate dữ liệu với nhiều rule cùng lúc
router.post('/rules/multiple/validate', ValidateController.validateWithMultipleRules);

module.exports = router;
