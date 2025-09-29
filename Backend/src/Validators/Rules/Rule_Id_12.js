/**
 * Rule 12: Thanh toán dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm, Sinh thiết tuyến giáp dưới hướng dẫn siêu âm, Tiêm khớp dưới hướng dẫn siêu âm …không thanh toán thêm dịch vụ Siêu âm
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_12 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm, Sinh thiết tuyến giáp dưới hướng dẫn siêu âm, Tiêm khớp dưới hướng dẫn siêu âm …không thanh toán thêm dịch vụ Siêu âm',
        ruleId: 'Rule_Id_12',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;
        const danhsachdichvu = [];
        for (const item of xml3_data) {
            danhsachdichvu.push(item.Ma_Dich_Vu);
        }
        if (danhsachdichvu.includes('18.0621.0090') && danhsachdichvu.includes('18.0001.0001')) {
            result.isValid = false;
            result.errors.push({ Id: item.Id, Error: 'Thanh toán dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm, Sinh thiết tuyến giáp dưới hướng dẫn siêu âm, Tiêm khớp dưới hướng dẫn siêu âm …không thanh toán thêm dịch vụ Siêu âm' });
        }
      
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm, Sinh thiết tuyến giáp dưới hướng dẫn siêu âm, Tiêm khớp dưới hướng dẫn siêu âm …không thanh toán thêm dịch vụ Siêu âm: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm, Sinh thiết tuyến giáp dưới hướng dẫn siêu âm, Tiêm khớp dưới hướng dẫn siêu âm …không thanh toán thêm dịch vụ Siêu âm';
    }

    return result;
};

module.exports = validateRule_Id_12;