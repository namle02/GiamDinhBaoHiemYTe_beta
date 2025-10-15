/**
 * Rule 33: Phẫu thuật cắt dạ dày không thanh toán thêm nạo vét hạch
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_33 = async (patientData) => {
    const result = {
        ruleName: 'Phẫu thuật cắt dạ dày không thanh toán thêm nạo vét hạch',
        ruleId: 'Rule_Id_33',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách dịch vụ từ Xml3
        const dsDichVu = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        const dsPTcatdaday = [
            '10.0457.0449',
            '03.3285.0448',
            '10.0455.0449',
            '10.0456.0448',
            '12.0199.0449',
            '12.0201.0449'
        ];

        const dsdvNaoVetHach = [
            '10.0459.0488',
            '10.0460.0488',
            '10.0461.0488',
            '10.0462.0488'
        ];

        // Lọc ra các dịch vụ phẫu thuật cắt dạ dày và nạo vét hạch
        const dsCatDaDay = dsDichVu.filter(dv => dsPTcatdaday.includes(dv.Ma_Dich_Vu));
        const dsNaoVetHach = dsDichVu.filter(dv => dsdvNaoVetHach.includes(dv.Ma_Dich_Vu));

        // Nếu có cả hai loại dịch vụ thì báo lỗi cho tất cả các dịch vụ liên quan
        if (dsCatDaDay.length > 0 && dsNaoVetHach.length > 0) {
            dsCatDaDay.forEach(dv => {
                result.errors.push({
                    Id: dv.Id,
                    Error: `Không được thanh toán đồng thời phẫu thuật cắt dạ dày (${dv.Ma_Dich_Vu}) và nạo vét hạch`
                });
            });
            dsNaoVetHach.forEach(dv => {
                result.errors.push({
                    Id: dv.Id,
                    Error: `Không được thanh toán đồng thời phẫu thuật cắt dạ dày và nạo vét hạch (${dv.Ma_Dich_Vu})`
                });
            });
            result.isValid = false;
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Phẫu thuật cắt dạ dày không thanh toán thêm nạo vét hạch: ${error.message}`);
        result.message = 'Lỗi khi validate Phẫu thuật cắt dạ dày không thanh toán thêm nạo vét hạch';
    }

    return result;
};

module.exports = validateRule_Id_33;