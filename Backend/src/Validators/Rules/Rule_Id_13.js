/**
 * Rule 13: Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_13 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.',
        ruleId: 'Rule_Id_13',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        const xml2_data = Array.isArray(patientData.Xml2) ? patientData.Xml2 : [];

        // Tìm xem có dịch vụ chạy thận nhân tạo không
        const dsChayThan = xml3_data.filter(item => item.Ma_Dich_Vu === '02.0495.0196');
        // Tìm xem có thuốc chống đông Enoxaparin (natri) hoặc Heparin (natri) không
        const dsThuocChongDong = xml2_data.filter(item => item.Ma_Thuoc === '40.445');

        if (dsChayThan.length > 0 && dsThuocChongDong.length > 0) {
            result.isValid = false;
            // Báo lỗi cho từng dòng có mã dịch vụ hoặc thuốc bị vi phạm
            dsChayThan.forEach(item => {
                result.errors.push({
                    Id: item.Id,
                    Error: 'Không được đồng thời thanh toán dịch vụ chạy thận nhân tạo (02.0495.0196) và thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) (40.445) do đã có trong cơ cấu giá kỹ thuật chạy thận nhân tạo.'
                });
            });
            dsThuocChongDong.forEach(item => {
                result.errors.push({
                    Id: item.Id,
                    Error: 'Không được đồng thời thanh toán dịch vụ chạy thận nhân tạo (02.0495.0196) và thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) (40.445) do đã có trong cơ cấu giá kỹ thuật chạy thận nhân tạo.'
                });
            });
        }
      
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.';
    }

    return result;
};

module.exports = validateRule_Id_13;