/**
 * Rule 24: Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_24 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh',
        ruleId: 'Rule_Id_24',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const danhsachmabacsihople = [
            '001068/BYT-CCHN',
            '033106/BYT-CCHN',
            '033268/BYT-CCHN',
            '000407/QNI-GPHN',
            '031380/BYT-CCHN',
            '005594/BYT-CCHN',
        ];

        const danhsachdichvu = [
            '03.4183.0271',
            '08.0006.0271',
            '08.0367.0271',
            '08.0378.0271'
        ];

        const xml3_data = patientData.Xml3 || [];

        xml3_data.forEach(item => {
            if (danhsachdichvu.includes(item.Ma_Dich_Vu)) {
                // Kiểm tra mã bác sĩ chỉ định
                const maBacSiChiDinh = item.Ma_Bac_Si;
                const maBacSiThucHien = item.Nguoi_Thuc_Hien;
                if ((!danhsachmabacsihople.includes(maBacSiChiDinh) && maBacSiChiDinh !== '') || (!danhsachmabacsihople.includes(maBacSiThucHien) && maBacSiThucHien !== '')) {
                    result.isValid = false;
                    result.errors.push({ Id: item.Id, Error: 'Thủy châm: bác sĩ chỉ định/thực hiện không đúng chức danh chuyên môn (TT 32/2023/TT-BYT)' });
                }
            }
        });

        if (result.errors.length > 0) {
            result.isValid = false;
            result.message = 'Có dịch vụ thủy châm do bác sĩ chỉ định hoặc mã bác sĩ thực hiện không đúng chức danh chuyên môn theo quy định.';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh';
    }

    return result;
};

module.exports = validateRule_Id_24;