/**
 * Rule 12: Thanh toán dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm, Sinh thiết tuyến giáp dưới hướng dẫn siêu âm, Tiêm khớp dưới hướng dẫn siêu âm …không thanh toán thêm dịch vụ Siêu âm
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_12 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm, Sinh thiết tuyến giáp dưới hướng dẫn siêu âm, Tiêm khớp dưới hướng dẫn siêu âm …không thanh toán thêm dịch vụ Siêu âm',
        ruleId: 'Rule_Id_12',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];

        // Tìm các dịch vụ có mã '18.0621.0090' (Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm...)
        const dichVuChocSinhThiet = xml3_data.filter(item => item.Ma_Dich_Vu === '18.0621.0090');
        
        // Tìm các dịch vụ có mã '18.0001.0001' (Siêu âm)
        const dichVuSieuAm = xml3_data.filter(item => item.Ma_Dich_Vu === '18.0001.0001');

        // Nếu có cả hai loại dịch vụ thì báo lỗi
        if (dichVuChocSinhThiet.length > 0 && dichVuSieuAm.length > 0) {
            result.isValid = false;
            
            // Báo lỗi cho tất cả các dịch vụ chọc sinh thiết
            dichVuChocSinhThiet.forEach(item => {
                result.errors.push({
                    Id: item.id || item.Id,
                    Error: 'Thanh toán dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm, Sinh thiết tuyến giáp dưới hướng dẫn siêu âm, Tiêm khớp dưới hướng dẫn siêu âm không được thanh toán thêm dịch vụ Siêu âm (18.0001.0001)'
                });
            });

            // Báo lỗi cho tất cả các dịch vụ siêu âm
            dichVuSieuAm.forEach(item => {
                result.errors.push({
                    Id: item.id || item.Id,
                    Error: 'Dịch vụ Siêu âm (18.0001.0001) không được thanh toán cùng với dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm (18.0621.0090) do đã có trong cơ cấu giá kỹ thuật'
                });
            });
        }
      
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm, Sinh thiết tuyến giáp dưới hướng dẫn siêu âm, Tiêm khớp dưới hướng dẫn siêu âm …không thanh toán thêm dịch vụ Siêu âm: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ Chọc sinh thiết u, hạch dưới hướng dẫn siêu âm, Sinh thiết tuyến giáp dưới hướng dẫn siêu âm, Tiêm khớp dưới hướng dẫn siêu âm …không thanh toán thêm dịch vụ Siêu âm';
    }

    return result;
};

module.exports = validateRule_Id_12;