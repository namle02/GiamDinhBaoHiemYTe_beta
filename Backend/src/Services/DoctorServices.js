const Doctor = require('../Repos/Models/Doctor');
const XLSX = require('xlsx');
const LogService = require('./LogService');

class DoctorServices {
    constructor() {
        this.doctorModel = Doctor;
    }

    /**
     * Import doctors từ file Excel
     */
    async importDoctorsFromExcel(filePath) {
        try {
            await LogService.info('DoctorServices', 'Bắt đầu import doctors từ Excel', {
                filePath
            });

            // Đọc file Excel
            const workbook = XLSX.readFile(filePath);
            const sheetName = workbook.SheetNames[0]; // Lấy sheet đầu tiên
            const worksheet = workbook.Sheets[sheetName];

            // Chuyển đổi sang JSON
            const jsonData = XLSX.utils.sheet_to_json(worksheet);

            if (!jsonData || jsonData.length === 0) {
                return {
                    success: false,
                    message: 'File Excel không có dữ liệu hoặc định dạng không đúng'
                };
            }

            const results = {
                success: true,
                totalRows: jsonData.length,
                successCount: 0,
                errorCount: 0,
                errors: [],
                importedDoctors: []
            };

            // Xử lý từng dòng dữ liệu
            for (let i = 0; i < jsonData.length; i++) {
                const row = jsonData[i];
                const rowNumber = i + 2; // +2 vì bắt đầu từ dòng 2 (dòng 1 là header)

                try {
                    // Transform dữ liệu từ Excel
                    const doctorData = this.transformExcelData(row);


                    // Kiểm tra doctor đã tồn tại chưa
                    const existingDoctor = await this.doctorModel.findOne({ ID: doctorData.ID });
                    if (existingDoctor) {
                        results.errorCount++;
                        results.errors.push({
                            row: rowNumber,
                            errors: ['Doctor với ID này đã tồn tại'],
                            data: row
                        });
                        continue;
                    }

                    // Tạo doctor mới
                    const doctor = new this.doctorModel(doctorData);
                    await doctor.save();

                    results.successCount++;
                    results.importedDoctors.push({
                        ID: doctorData.ID,
                        HO_TEN: doctorData.HO_TEN,
                        MA_BHXH: doctorData.MA_BHXH
                    });

                } catch (error) {
                    results.errorCount++;
                    results.errors.push({
                        row: rowNumber,
                        errors: [error.message],
                        data: row
                    });
                }
            }

            await LogService.success('DoctorServices', 'Import doctors hoàn thành', {
                totalRows: results.totalRows,
                successCount: results.successCount,
                errorCount: results.errorCount
            });

            return results;

        } catch (error) {
            await LogService.error('DoctorServices', 'Lỗi khi import doctors từ Excel', error);
            return {
                success: false,
                message: 'Lỗi khi đọc file Excel',
                error: error.message
            };
        }
    }

    /**
     * Transform dữ liệu từ Excel sang format MongoDB
     */
    transformExcelData(row) {
        const doctorData = {};

        // Map các trường từ Excel
        const fieldMapping = {
            'STT': 'STT',
            'MA_LOAI_KCB': 'MA_LOAI_KCB',
            'MA_KHOA': 'MA_KHOA',
            'TEN_KHOA': 'TEN_KHOA',
            'MA_BHXH': 'MA_BHXH',
            'HO_TEN': 'HO_TEN',
            'GIOI_TINH': 'GIOI_TINH',
            'CHUCDANH_NN': 'CHUCDANH_NN',
            'VI_TRI': 'VI_TRI',
            'MACCHN': 'MACCHN',
            'NGAYCAP_CCHN': 'NGAYCAP_CCHN',
            'NOICAP_CCHN': 'NOICAP_CCHN',
            'PHAMVI_CM': 'PHAMVI_CM',
            'PHAMVI_CMBS': 'PHAMVI_CMBS',
            'DVKT_KHAC': 'DVKT_KHAC',
            'VB_PHANCONG': 'VB_PHANCONG',
            'THOIGIAN_DK': 'THOIGIAN_DK',
            'THOIGIAN_NGAY': 'THOIGIAN_NGAY',
            'THOIGIAN_TUAN': 'THOIGIAN_TUAN',
            'CSKCB_KHAC': 'CSKCB_KHAC',
            'CSKCB_CGKT': 'CSKCB_CGKT',
            'QD_CGKT': 'QD_CGKT',
            'TU_NGAY': 'TU_NGAY',
            'DEN_NGAY': 'DEN_NGAY',
            'ID': 'ID'
        };

        // Transform từng trường
        for (const [excelField, dbField] of Object.entries(fieldMapping)) {
            if (row[excelField] !== undefined && row[excelField] !== null && row[excelField] !== '') {
                doctorData[dbField] = this.transformFieldValue(dbField, row[excelField]);
            }
        }

        return doctorData;
    }

    /**
     * Transform giá trị của từng trường theo kiểu dữ liệu
     */
    transformFieldValue(fieldName, value) {
        switch (fieldName) {
            case 'STT':
            case 'MA_LOAI_KCB':
            case 'MA_BHXH':
            case 'GIOI_TINH':
            case 'CHUCDANH_NN':
            case 'VI_TRI':
            case 'PHAMVI_CMBS':
            case 'VB_PHANCONG':
            case 'THOIGIAN_DK':
            case 'ID':
                return parseInt(value) || 0;

            case 'NGAYCAP_CCHN':
            case 'TU_NGAY':
            case 'DEN_NGAY':
                return this.parseDate(value);

            case 'PHAMVI_CM':
                return this.parseArray(value, 'number');

            case 'DVKT_KHAC':
            case 'MA_KHOA':
                return this.parseArray(value, 'string');


            case 'TEN_KHOA':
            case 'HO_TEN':
            case 'MACCHN':
            case 'NOICAP_CCHN':
            case 'THOIGIAN_NGAY':
            case 'THOIGIAN_TUAN':
            case 'CSKCB_KHAC':
            case 'CSKCB_CGKT':
            case 'QD_CGKT':
                return String(value).trim();

            default:
                return value;
        }
    }

    /**
     * Parse date từ các format khác nhau
     */
    parseDate(value) {
        if (!value) return null;

        // Nếu là số (Excel date serial number)
        if (typeof value === 'number') {
            return new Date((value - 25569) * 86400 * 1000);
        }

        // Nếu là string
        if (typeof value === 'string') {
            // Format: 7/2/2014 0:00
            if (value.includes('/')) {
                return new Date(value);
            }
            // Format: 20150106
            if (/^\d{8}$/.test(value)) {
                const year = value.substring(0, 4);
                const month = value.substring(4, 6);
                const day = value.substring(6, 8);
                return new Date(year, month - 1, day);
            }
        }

        return new Date(value);
    }

    /**
     * Parse string thành array
     */
    parseArray(value, type = 'string') {
        if (!value) return [];

        if (typeof value === 'string') {
            const items = value.split(';').map(item => item.trim()).filter(item => item);
            if (type === 'number') {
                return items.map(item => parseInt(item)).filter(item => !isNaN(item));
            }
            return items;
        }

        if (Array.isArray(value)) {
            return value;
        }

        return [];
    }

    /**
     * Tạo doctor mới
     */
    async createDoctor(doctorData) {
        try {


            // Kiểm tra doctor đã tồn tại
            const existingDoctor = await this.doctorModel.findOne({ ID: doctorData.ID });
            if (existingDoctor) {
                return {
                    success: false,
                    message: 'Doctor với ID này đã tồn tại'
                };
            }

            const doctor = new this.doctorModel(doctorData);
            await doctor.save();

            return {
                success: true,
                message: 'Tạo doctor thành công',
                data: doctor
            };
        } catch (error) {
            return {
                success: false,
                message: 'Lỗi khi tạo doctor',
                error: error.message
            };
        }
    }

    /**
     * Lấy danh sách doctors
     */
    async getDoctors(page = 1, limit = 10, search = '') {
        try {
            const skip = (page - 1) * limit;
            let query = {};

            if (search) {
                query = {
                    $or: [
                        { HO_TEN: { $regex: search, $options: 'i' } },
                        { MA_BHXH: { $regex: search, $options: 'i' } },
                        { MACCHN: { $regex: search, $options: 'i' } },
                        { TEN_KHOA: { $regex: search, $options: 'i' } }
                    ]
                };
            }

            const doctors = await this.doctorModel
                .find(query)
                .skip(skip)
                .limit(limit)
                .sort({ createdAt: -1 });

            const total = await this.doctorModel.countDocuments(query);

            return {
                success: true,
                message: 'Lấy danh sách doctors thành công',
                data: {
                    doctors,
                    pagination: {
                        currentPage: page,
                        totalPages: Math.ceil(total / limit),
                        totalItems: total,
                        itemsPerPage: limit
                    }
                }
            };
        } catch (error) {
            return {
                success: false,
                message: 'Lỗi khi lấy danh sách doctors',
                error: error.message
            };
        }
    }

    /**
     * Lấy doctor theo ID
     */
    async getDoctorById(id) {
        try {
            const doctor = await this.doctorModel.findOne({ ID: id });

            if (!doctor) {
                return {
                    success: false,
                    message: 'Không tìm thấy doctor'
                };
            }

            return {
                success: true,
                message: 'Lấy thông tin doctor thành công',
                data: doctor
            };
        } catch (error) {
            return {
                success: false,
                message: 'Lỗi khi lấy thông tin doctor',
                error: error.message
            };
        }
    }

    /**
     * Cập nhật doctor
     */
    async updateDoctor(id, updateData) {
        try {

            const doctor = await this.doctorModel.findOneAndUpdate(
                { ID: id },
                updateData,
                { new: true, runValidators: true }
            );

            if (!doctor) {
                return {
                    success: false,
                    message: 'Không tìm thấy doctor'
                };
            }

            return {
                success: true,
                message: 'Cập nhật doctor thành công',
                data: doctor
            };
        } catch (error) {
            return {
                success: false,
                message: 'Lỗi khi cập nhật doctor',
                error: error.message
            };
        }
    }

    /**
     * Xóa doctor
     */
    async deleteDoctor(id) {
        try {
            const doctor = await this.doctorModel.findOneAndDelete({ ID: id });

            if (!doctor) {
                return {
                    success: false,
                    message: 'Không tìm thấy doctor'
                };
            }

            return {
                success: true,
                message: 'Xóa doctor thành công',
                data: doctor
            };
        } catch (error) {
            return {
                success: false,
                message: 'Lỗi khi xóa doctor',
                error: error.message
            };
        }
    }
}

module.exports = new DoctorServices();
