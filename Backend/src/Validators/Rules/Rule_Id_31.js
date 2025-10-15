/**
 * Rule 31: Không thanh toán Hirzt và Blondeau đồng thời
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_31 = async (patientData) => {
    const result = {
        ruleName: 'Không thanh toán Hirzt và Blondeau đồng thời',
        ruleId: 'Rule_Id_31',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        // Lấy danh sách các dịch vụ có mã cần kiểm tra
        const dsHirzt = xml3_data.filter(item => item.Ma_Dich_Vu === '18.0072.0028');
        const dsBlondeau = xml3_data.filter(item => item.Ma_Dich_Vu === '18.0073.0028');

        if (dsHirzt.length > 0 && dsBlondeau.length > 0) {
            // Nếu vừa có dịch vụ Hirzt vừa có Blondeau thì báo lỗi cho tất cả các dịch vụ này
            dsHirzt.forEach(item => {
                result.errors.push({
                    Id: item.Id,
                    Error: 'Không được đồng thời thanh toán dịch vụ Hirzt (18.0072.0028) và Blondeau (18.0073.0028)'
                });
            });
            dsBlondeau.forEach(item => {
                result.errors.push({
                    Id: item.Id,
                    Error: 'Không được đồng thời thanh toán dịch vụ Hirzt (18.0072.0028) và Blondeau (18.0073.0028)'
                });
            });
            result.isValid = false;
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Không thanh toán Hirzt và Blondeau đồng thời: ${error.message}`);
        result.message = 'Lỗi khi validate Không thanh toán Hirzt và Blondeau đồng thời';
    }

    return result;
};

module.exports = validateRule_Id_31;