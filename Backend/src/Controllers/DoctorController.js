const DoctorServices = require('../Services/DoctorServices');
const LogService = require('../Services/LogService');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Cấu hình multer để upload file
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        const uploadDir = 'uploads/doctors';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'doctor-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const fileFilter = (req, file, cb) => {
    const allowedTypes = [
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // .xlsx
        'application/vnd.ms-excel', // .xls
        'text/csv' // .csv
    ];
    
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Chỉ cho phép file Excel (.xlsx, .xls) hoặc CSV'), false);
    }
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 100 * 1024 * 1024 // 10MB
    }
});

class DoctorController {
    /**
     * Upload và import doctors từ file Excel
     */
    async importDoctorsFromExcel(req, res) {
        try {
            await LogService.info('DoctorController', 'Bắt đầu import doctors từ Excel', {
                filename: req.file?.originalname,
                filesize: req.file?.size
            }, req);

            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    message: 'Vui lòng chọn file Excel để upload'
                });
            }

            const filePath = req.file.path;
            const result = await DoctorServices.importDoctorsFromExcel(filePath);

            // Xóa file tạm sau khi xử lý
            try {
                fs.unlinkSync(filePath);
            } catch (deleteError) {
                console.warn('Không thể xóa file tạm:', deleteError.message);
            }

            if (result.success) {
                await LogService.success('DoctorController', 'Import doctors thành công', {
                    totalRows: result.totalRows,
                    successCount: result.successCount,
                    errorCount: result.errorCount
                }, req);

                res.status(200).json({
                    success: true,
                    message: `Import hoàn thành. Thành công: ${result.successCount}/${result.totalRows} bản ghi`,
                    data: {
                        totalRows: result.totalRows,
                        successCount: result.successCount,
                        errorCount: result.errorCount,
                        importedDoctors: result.importedDoctors,
                        errors: result.errors
                    }
                });
            } else {
                await LogService.warn('DoctorController', 'Import doctors thất bại', {
                    error: result.message
                }, req);

                res.status(400).json({
                    success: false,
                    message: result.message,
                    error: result.error
                });
            }
        } catch (error) {
            await LogService.error('DoctorController', 'Lỗi khi import doctors từ Excel', error, req);
            
            // Xóa file tạm nếu có lỗi
            if (req.file && req.file.path) {
                try {
                    fs.unlinkSync(req.file.path);
                } catch (deleteError) {
                    console.warn('Không thể xóa file tạm:', deleteError.message);
                }
            }

            res.status(500).json({
                success: false,
                message: 'Lỗi server khi import doctors',
                error: error.message
            });
        }
    }

    /**
     * Tạo doctor mới
     */
    async createDoctor(req, res) {
        try {
            await LogService.info('DoctorController', 'Bắt đầu tạo doctor mới', {
                doctorId: req.body.ID,
                doctorName: req.body.HO_TEN
            }, req);
            
            const result = await DoctorServices.createDoctor(req.body);

            if (result.success) {
                await LogService.success('DoctorController', 'Tạo doctor thành công', {
                    doctorId: req.body.ID,
                    doctorName: req.body.HO_TEN
                }, req);
                
                res.status(201).json({
                    success: result.success,
                    message: result.message,
                    data: result.data
                });
            } else {
                await LogService.warn('DoctorController', 'Tạo doctor thất bại', {
                    doctorId: req.body.ID,
                    errors: result.errors
                }, req);
                
                res.status(400).json({
                    success: false,
                    message: result.message,
                    errors: result.errors
                });
            }
        } catch (error) {
            await LogService.error('DoctorController', 'Lỗi khi tạo doctor', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lấy danh sách doctors
     */
    async getDoctors(req, res) {
        try {
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 10;
            const search = req.query.search || '';
            
            await LogService.info('DoctorController', 'Lấy danh sách doctors', {
                page,
                limit,
                search
            }, req);
            
            const result = await DoctorServices.getDoctors(page, limit, search);
            
            if (result.success) {
                await LogService.success('DoctorController', 'Lấy danh sách doctors thành công', {
                    total: result.data.pagination.totalItems,
                    page,
                    limit
                }, req);
                
                res.status(200).json({
                    success: true,
                    message: result.message,
                    data: result.data
                });
            } else {
                await LogService.warn('DoctorController', 'Lấy danh sách doctors thất bại', {
                    error: result.message
                }, req);
                
                res.status(400).json({
                    success: false,
                    message: result.message,
                    error: result.error
                });
            }
        } catch (error) {
            await LogService.error('DoctorController', 'Lỗi khi lấy danh sách doctors', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lấy doctor theo ID
     */
    async getDoctorById(req, res) {
        try {
            const { id } = req.params;
            
            await LogService.info('DoctorController', 'Lấy doctor theo ID', {
                doctorId: id
            }, req);
            
            const result = await DoctorServices.getDoctorById(id);
            
            if (result.success) {
                await LogService.success('DoctorController', 'Lấy doctor thành công', {
                    doctorId: id
                }, req);
                
                res.status(200).json({
                    success: true,
                    message: result.message,
                    data: result.data
                });
            } else {
                await LogService.warn('DoctorController', 'Không tìm thấy doctor', {
                    doctorId: id
                }, req);
                
                res.status(404).json({
                    success: false,
                    message: result.message
                });
            }
        } catch (error) {
            await LogService.error('DoctorController', 'Lỗi khi lấy doctor theo ID', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Cập nhật doctor
     */
    async updateDoctor(req, res) {
        try {
            const { id } = req.params;
            
            await LogService.info('DoctorController', 'Cập nhật doctor', {
                doctorId: id,
                updateData: Object.keys(req.body)
            }, req);
            
            const result = await DoctorServices.updateDoctor(id, req.body);
            
            if (result.success) {
                await LogService.success('DoctorController', 'Cập nhật doctor thành công', {
                    doctorId: id
                }, req);
                
                res.status(200).json({
                    success: true,
                    message: result.message,
                    data: result.data
                });
            } else {
                await LogService.warn('DoctorController', 'Cập nhật doctor thất bại', {
                    doctorId: id,
                    errors: result.errors
                }, req);
                
                res.status(400).json({
                    success: false,
                    message: result.message,
                    errors: result.errors
                });
            }
        } catch (error) {
            await LogService.error('DoctorController', 'Lỗi khi cập nhật doctor', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Xóa doctor
     */
    async deleteDoctor(req, res) {
        try {
            const { id } = req.params;
            
            await LogService.info('DoctorController', 'Xóa doctor', {
                doctorId: id
            }, req);
            
            const result = await DoctorServices.deleteDoctor(id);
            
            if (result.success) {
                await LogService.success('DoctorController', 'Xóa doctor thành công', {
                    doctorId: id
                }, req);
                
                res.status(200).json({
                    success: true,
                    message: result.message,
                    data: result.data
                });
            } else {
                await LogService.warn('DoctorController', 'Không tìm thấy doctor để xóa', {
                    doctorId: id
                }, req);
                
                res.status(404).json({
                    success: false,
                    message: result.message
                });
            }
        } catch (error) {
            await LogService.error('DoctorController', 'Lỗi khi xóa doctor', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lấy template Excel để import
     */
    async getExcelTemplate(req, res) {
        try {
            const XLSX = require('xlsx');
            
            // Tạo workbook mới
            const workbook = XLSX.utils.book_new();
            
            // Định nghĩa các header columns
            const headers = [
                'STT', 'MA_LOAI_KCB', 'MA_KHOA', 'TEN_KHOA', 'MA_BHXH', 'HO_TEN',
                'GIOI_TINH', 'CHUCDANH_NN', 'VI_TRI', 'MACCHN', 'NGAYCAP_CCHN',
                'NOICAP_CCHN', 'PHAMVI_CM', 'PHAMVI_CMBS', 'DVKT_KHAC', 'VB_PHANCONG',
                'THOIGIAN_DK', 'THOIGIAN_NGAY', 'THOIGIAN_TUAN', 'CSKCB_KHAC',
                'CSKCB_CGKT', 'QD_CGKT', 'TU_NGAY', 'DEN_NGAY', 'ID'
            ];
            
            // Tạo worksheet với headers
            const worksheet = XLSX.utils.aoa_to_sheet([headers]);
            
            // Thêm worksheet vào workbook
            XLSX.utils.book_append_sheet(workbook, worksheet, 'Doctors');
            
            // Tạo buffer
            const buffer = XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
            
            res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            res.setHeader('Content-Disposition', 'attachment; filename="doctor_template.xlsx"');
            res.send(buffer);
            
        } catch (error) {
            await LogService.error('DoctorController', 'Lỗi khi tạo template Excel', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi khi tạo template Excel',
                error: error.message
            });
        }
    }
}

// Export cả controller và multer upload middleware
module.exports = {
    controller: new DoctorController(),
    upload: upload.single('excelFile')
};
