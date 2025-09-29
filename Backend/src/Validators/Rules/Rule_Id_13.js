/**
 * Rule 13: Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_13 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.',
        ruleId: 'Rule_Id_13',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;
        const xml2_data = patientData.Xml2;
        const danhsachdichvu = [];
        for (const item of xml3_data) {
            danhsachdichvu.push(item.Ma_Dich_Vu);
        }
        for(const item of xml2_data) {
            danhsachdichvu.push(item.Ma_Thuoc);
        }
        if (danhsachdichvu.includes('02.0495.0196') && danhsachdichvu.includes('40.445')) {
            result.isValid = false;
            result.errors.push({ Id: item.Id, Error: 'Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.' });
        }
      
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.';
    }

    return result;
};

module.exports = validateRule_Id_13;