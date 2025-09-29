/**
 * Rule 4: Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ)
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_4 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ)',
        ruleId: 'Rule_Id_4',
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
        if (danhsachdichvu.includes('20.0084.0440') ) {
            if (danhsachdichvu.includes('20.0083.0104')) {
                result.isValid = false;
                result.errors.push({ Id: item.Id, Error: 'Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ)' });
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ): ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ)';
    }

    return result;
};

module.exports = validateRule_Id_4;