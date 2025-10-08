const express = require('express');
const router = express.Router();
const DoctorController = require('../Controllers/DoctorController');

// Routes cho Doctor CRUD operations
router.post('/', DoctorController.controller.createDoctor);
router.get('/', DoctorController.controller.getDoctors);
router.get('/template', DoctorController.controller.getExcelTemplate);
router.get('/:id', DoctorController.controller.getDoctorById);
router.put('/:id', DoctorController.controller.updateDoctor);
router.delete('/:id', DoctorController.controller.deleteDoctor);

// Route đặc biệt cho import Excel
router.post('/import', DoctorController.upload, DoctorController.controller.importDoctorsFromExcel);

module.exports = router;
