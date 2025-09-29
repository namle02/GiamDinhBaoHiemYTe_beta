const PatientServices = require('../Services/PatientServices');
const LogService = require('../Services/LogService');

class PatientController {
    /**
     * Tạo bệnh nhân mới
     */
    async createPatient(req, res) {
        try {
            await LogService.info('PatientController', 'Bắt đầu tạo bệnh nhân mới', {
                patientId: req.body.PatientID
            }, req);
            
            const result = await PatientServices.createPatient(req.body);

            if (result.success) {
                await LogService.success('PatientController', 'Tạo bệnh nhân thành công', {
                    patientId: req.body.PatientID,
                    validationErrors: result.errors
                }, req);
                
                res.status(201).json({
                    success: result.success,
                    message: result.message,
                    data: result.data
                });
            } else {
                await LogService.warn('PatientController', 'Tạo bệnh nhân thất bại, bệnh nhân đã tồn tại', {
                    patientId: req.body.PatientID,
                    errors: result.errors
                }, req);
                
                res.status(200).json({
                    success: false,
                    message: result.message,
                    errors: result.errors
                });
            }
        } catch (error) {
            await LogService.error('PatientController', 'Lỗi khi tạo bệnh nhân', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lấy danh sách bệnh nhân
     */
    async getPatients(req, res) {
        try {
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 10;
            const search = req.query.search || '';
            
            await LogService.info('PatientController', 'Lấy danh sách bệnh nhân', {
                page,
                limit,
                search
            }, req);
            
            const result = await PatientServices.getPatients(page, limit, search);
            
            if (result.success) {
                await LogService.success('PatientController', 'Lấy danh sách bệnh nhân thành công', {
                    total: result.data.total,
                    page,
                    limit
                }, req);
                
                res.status(200).json({
                    success: true,
                    message: result.message,
                    data: result.data
                });
            } else {
                await LogService.warn('PatientController', 'Lấy danh sách bệnh nhân thất bại', {
                    error: result.message
                }, req);
                
                res.status(400).json({
                    success: false,
                    message: result.message,
                    error: result.error
                });
            }
        } catch (error) {
            await LogService.error('PatientController', 'Lỗi khi lấy danh sách bệnh nhân', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lấy bệnh nhân theo ID
     */
    async getPatientById(req, res) {
        try {
            const { id } = req.params;
            const result = await PatientServices.getPatientById(id);
            
            if (result.success) {
                res.status(200).json({
                    success: true,
                    message: result.message,
                    data: result.data
                });
            } else {
                res.status(404).json({
                    success: false,
                    message: result.message
                });
            }
        } catch (error) {
            console.error('Lỗi trong PatientController.getPatientById:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Cập nhật bệnh nhân
     */
    async updatePatient(req, res) {
        try {
            const { id } = req.params;
            const result = await PatientServices.updatePatient(id, req.body);
            
            if (result.success) {
                res.status(200).json({
                    success: true,
                    message: result.message,
                    data: result.data
                });
            } else {
                res.status(400).json({
                    success: false,
                    message: result.message,
                    errors: result.errors
                });
            }
        } catch (error) {
            console.error('Lỗi trong PatientController.updatePatient:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Xóa bệnh nhân
     */
    async deletePatient(req, res) {
        try {
            const { id } = req.params;
            const result = await PatientServices.deletePatient(id);
            
            if (result.success) {
                res.status(200).json({
                    success: true,
                    message: result.message,
                    data: result.data
                });
            } else {
                res.status(404).json({
                    success: false,
                    message: result.message
                });
            }
        } catch (error) {
            console.error('Lỗi trong PatientController.deletePatient:', error);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }
}

module.exports = new PatientController();