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
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;
        const danhsachdichvu = [];
        xml3_data.forEach(item => {
            danhsachdichvu.push(item.Ma_Dich_Vu);
        });
        if (danhsachdichvu.includes('02.0296.0500') || danhsachdichvu.includes('02.0271.0140')) {
            if (danhsachdichvu.includes('02.0262.0136')) {
                result.isValid = false;
                result.errors.push({ Id: item.Id, Error: 'Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm' });
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm';
    }

    return result;
};

module.exports = validateRule_Id_3;