/**
 * Rule 24: Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const Doctor = require('../../Repos/Models/Doctor');

const validateRule_Id_24 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh',
        ruleId: 'Rule_Id_24',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const danhsachdichvu = [
            '03.4183.0271',
            '08.0006.0271',
            '08.0367.0271',
            '08.0378.0271'
        ];

        const xml3_data = patientData.Xml3 || [];

        // Đếm số dịch vụ thủy châm
        const dichVuThuyCham = xml3_data.filter(item => danhsachdichvu.includes(item.Ma_Dich_Vu));

        for (const item of xml3_data) {
            if (danhsachdichvu.includes(item.Ma_Dich_Vu)) {
                // Chỉ kiểm tra người thực hiện
                const maBacSiThucHien = item.Nguoi_Thuc_Hien;
                
                let isValidThucHien = true;

                // Kiểm tra người thực hiện
                if (maBacSiThucHien && maBacSiThucHien !== '') {
                    const doctorThucHien = await Doctor.findOne({ MACCHN: maBacSiThucHien }).lean();
                    
                    if (!doctorThucHien) {
                        isValidThucHien = false;
                    } else {
                        if (Array.isArray(doctorThucHien.PHAMVI_CM)) {
                            if (!doctorThucHien.PHAMVI_CM.includes(108)) {
                                isValidThucHien = false;
                            }
                        } else {
                            isValidThucHien = false;
                        }
                    }
                } else {
                    isValidThucHien = false; // Nếu không có mã thì cũng coi là không hợp lệ
                }

                if (!isValidThucHien) {
                    result.isValid = false;
                    result.errors.push({ Id: item.Id, Error: 'Thủy châm: người thực hiện không đúng chức danh chuyên môn (TT 32/2023/TT-BYT)' });
                }
            }
        }

        if (result.errors.length > 0) {
            result.isValid = false;
            result.message = 'Có dịch vụ thủy châm do người thực hiện không đúng chức danh chuyên môn theo quy định.';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh';
    }

    return result;
};

module.exports = validateRule_Id_24;