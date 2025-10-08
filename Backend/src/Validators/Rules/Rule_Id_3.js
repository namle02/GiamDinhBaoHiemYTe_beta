/**
 * Rule 3: Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_3 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm',
        ruleId: 'Rule_Id_3',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        // Kiểm tra nếu có dịch vụ 02.0296.0500 hoặc 02.0271.0140
        const coDichVuCanThiep = xml3_data.some(item => item.Ma_Dich_Vu === '02.0296.0500' || item.Ma_Dich_Vu === '02.0271.0140');
        // Kiểm tra nếu có dịch vụ 02.0262.0136
        const dichVuNoiSoi = xml3_data.filter(item => item.Ma_Dich_Vu === '02.0262.0136');

        if (coDichVuCanThiep && dichVuNoiSoi.length > 0) {
            result.isValid = false;
            dichVuNoiSoi.forEach(item => {
                result.errors.push({
                    Id: item.Id,
                    Error: 'Không được thanh toán đồng thời dịch vụ can thiệp ống tiêu hóa (02.0296.0500 hoặc 02.0271.0140) với dịch vụ Nội soi đại trực tràng toàn bộ ống mềm (02.0262.0136)'
                });
            });
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm';
    }

    return result;
};

module.exports = validateRule_Id_3;