/**
 * Rule 19: Thanh toán siêu âm hệ tiết niệu hoặc siêu âm tử cung phần phụ đồng thời với siêu âm ổ bụng, không đúng quy trình kỹ thuật số thứ tự 73 Quyết định số 3805/QĐ-BYT ngày 25/9/2014 của Bộ Y tế tài liệu “Hướng dẫn quy trình kỹ thuật nội khoa, chuyên ngành tiêu hóa”.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_19 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán siêu âm hệ tiết niệu hoặc siêu âm tử cung phần phụ đồng thời với siêu âm ổ bụng, không đúng quy trình kỹ thuật số thứ tự 73 Quyết định số 3805/QĐ-BYT ngày 25/9/2014 của Bộ Y tế tài liệu “Hướng dẫn quy trình kỹ thuật nội khoa, chuyên ngành tiêu hóa”.',
        ruleId: 'Rule_Id_19',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        const hasDichVu1 = xml3_data.some(item => item.Ma_Dich_Vu === '18.0015.0001');
        const hasDichVu2 = xml3_data.some(item => item.Ma_Dich_Vu === '18.0016.0001');

        if (hasDichVu1 && hasDichVu2) {
            result.isValid = false;
            xml3_data.forEach(item => {
                if (item.Ma_Dich_Vu === '18.0015.0001' || item.Ma_Dich_Vu === '18.0016.0001') {
                    result.errors.push({ Id: item.id || item.Id, Error: 'Không được đồng thời có 18.0015.0001 và 18.0016.0001 trong cùng hồ sơ' });
                }
            });
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi kiểm tra mã dịch vụ: ${error.message}`);
        result.message = 'Lỗi khi validate mã dịch vụ';
    }

    return result;
};

module.exports = validateRule_Id_19;