/**
 * Rule 2: Thanh toán dịch vụ nội soi can thiệp dạ dày tá - tràng không thanh toán thêm Nội soi thực quản - dạ dày - tá tràng
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_2 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ nội soi can thiệp dạ dày tá - tràng không thanh toán thêm Nội soi thực quản - dạ dày - tá tràng',
        ruleId: 'Rule_Id_2',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
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
        if (danhsachdichvu.includes('02.0295.0498') || danhsachdichvu.includes('02.0296.0500')) {
            if (danhsachdichvu.includes('02.0304.0134')) {
                result.isValid = false;
                result.errors.push({ Id: item.Id, Error: 'Thanh toán dịch vụ nội soi can thiệp dạ dày tá - tràng không thanh toán thêm Nội soi thực quản - dạ dày - tá tràng' });
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ nội soi can thiệp dạ dày tá - tràng không thanh toán thêm Nội soi thực quản - dạ dày - tá tràng: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ nội soi can thiệp dạ dày tá - tràng không thanh toán thêm Nội soi thực quản - dạ dày - tá tràng';
    }

    return result;
};

module.exports = validateRule_Id_2;