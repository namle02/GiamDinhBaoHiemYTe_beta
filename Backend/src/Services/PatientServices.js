const PatientData = require('../Repos/Models/PatientModel');
const ValidationService = require('./RuleService');

class PatientServices {
    constructor() {
        this.patientModel = PatientData;
    }

    /**
     * Tạo bệnh nhân mới
     */
    async createPatient(patientData) {
        try {
            // Validate dữ liệu trước khi lưu
            const validationResult = await ValidationService.validatePatientData(patientData);

            
            // Transform dữ liệu XML
            const transformedData = this.transformPatientData(patientData);

            // Tạo patient mới
            transformedData.PatientID = patientData.PatientID;
            // check exist patient
            const existPatient = await this.patientModel.findOne({ PatientID: transformedData.PatientID });
            if (existPatient) {
                return {
                    success: true,
                    message: 'Bệnh nhân đã tồn tại',
                    data: validationResult
                };
            }

            const patient = new this.patientModel(transformedData);
            await patient.save();

            // Trả về kết quả, bất kể validate thành công hay thất bại
            if (!validationResult.overallValid) {
                return {
                    success: true,
                    message: 'Dữ liệu không hợp lệ nhưng vẫn lưu bệnh nhân',
                    data: validationResult
                };
            }

            return {
                success: true,
                message: 'Tạo bệnh nhân thành công',
                data: validationResult
            };
        } catch (error) {
            console.error('Lỗi khi tạo bệnh nhân:', error);
            return {
                success: false,
                message: 'Lỗi khi tạo bệnh nhân',
                error: error.message
            };
        }
    }

    /**
     * Lấy danh sách bệnh nhân
     */
    async getPatients(page = 1, limit = 10, search = '') {
        try {
            const skip = (page - 1) * limit;
            let query = {};
            
            if (search) {
                query = {
                    $or: [
                        { PatientID: { $regex: search, $options: 'i' } }
                    ]
                };
            }
            
            const patients = await this.patientModel
                .find(query)
                .skip(skip)
                .limit(limit)
                .sort({ createdAt: -1 });
            
            const total = await this.patientModel.countDocuments(query);
            
            return {
                success: true,
                message: 'Lấy danh sách bệnh nhân thành công',
                data: {
                    patients,
                    pagination: {
                        currentPage: page,
                        totalPages: Math.ceil(total / limit),
                        totalItems: total,
                        itemsPerPage: limit
                    }
                }
            };
        } catch (error) {
            console.error('Lỗi khi lấy danh sách bệnh nhân:', error);
            return {
                success: false,
                message: 'Lỗi khi lấy danh sách bệnh nhân',
                error: error.message
            };
        }
    }

    /**
     * Lấy bệnh nhân theo ID
     */
    async getPatientById(patientId) {
        try {
            const patient = await this.patientModel.findOne({ PatientID: patientId });
            
            if (!patient) {
                return {
                    success: false,
                    message: 'Không tìm thấy bệnh nhân'
                };
            }
            
            return {
                success: true,
                message: 'Lấy thông tin bệnh nhân thành công',
                data: patient
            };
        } catch (error) {
            console.error('Lỗi khi lấy thông tin bệnh nhân:', error);
            return {
                success: false,
                message: 'Lỗi khi lấy thông tin bệnh nhân',
                error: error.message
            };
        }
    }

    /**
     * Cập nhật bệnh nhân
     */
    async updatePatient(patientId, updateData) {
        try {
            // Validate dữ liệu trước khi cập nhật
            const validationResult = await ValidationService.validatePatientData(updateData);
            
            if (!validationResult.isValid) {
                return {
                    success: false,
                    message: 'Dữ liệu không hợp lệ',
                    errors: validationResult.errors
                };
            }

            // Transform dữ liệu XML
            const transformedData = this.transformPatientData(updateData);
            
            const patient = await this.patientModel.findOneAndUpdate(
                patientId,
                transformedData,
                { new: true, runValidators: true }
            );
            
            if (!patient) {
                return {
                    success: false,
                    message: 'Không tìm thấy bệnh nhân'
                };
            }
            
            return {
                success: true,
                message: 'Cập nhật bệnh nhân thành công',
                data: patient
            };
        } catch (error) {
            console.error('Lỗi khi cập nhật bệnh nhân:', error);
            return {
                success: false,
                message: 'Lỗi khi cập nhật bệnh nhân',
                error: error.message
            };
        }
    }

    /**
     * Xóa bệnh nhân
     */
    async deletePatient(patientId) {
        try {
            const patient = await this.patientModel.findOneAndDelete({ PatientID: patientId });
            
            if (!patient) {
                return {
                    success: false,
                    message: 'Không tìm thấy bệnh nhân'
                };
            }
            
            return {
                success: true,
                message: 'Xóa bệnh nhân thành công',
                data: patient
            };
        } catch (error) {
            console.error('Lỗi khi xóa bệnh nhân:', error);
            return {
                success: false,
                message: 'Lỗi khi xóa bệnh nhân',
                error: error.message
            };
        }
    }

    /**
     * Transform dữ liệu XML từ client
     */
    transformPatientData(data) {
        const transformedData = {
            PatientID: data.PatientID
        };

        // Transform các XML arrays
        const xmlFields = ['Xml0', 'Xml1', 'Xml2', 'Xml3', 'Xml4', 'Xml5', 'Xml6', 'Xml7', 'Xml8', 'Xml9', 'Xml10', 'Xml11', 'Xml13', 'Xml14', 'Xml15', 'DsBenhNhanLoiMaMay'];
        
        for (const field of xmlFields) {
            if (data[field] && Array.isArray(data[field])) {
                transformedData[field] = this.convertXmlKeysToSnakeCase(data[field]);
            } else {
                transformedData[field] = [];
            }
        }

        return transformedData;
    }

    /**
     * Convert nested object keys, giữ nguyên naming convention
     */
    convertXmlKeysToSnakeCase(obj) {
        if (Array.isArray(obj)) {
            return obj.map(item => this.convertXmlKeysToSnakeCase(item));
        } else if (obj !== null && typeof obj === 'object') {
            return Object.keys(obj).reduce((result, key) => {
                // Giữ nguyên key naming từ client: Ma_Lk, Ma_Dich_Vu, etc.
                result[key] = this.convertXmlKeysToSnakeCase(obj[key]);
                return result;
            }, {});
        }
        return obj;
    }
}

module.exports = new PatientServices();