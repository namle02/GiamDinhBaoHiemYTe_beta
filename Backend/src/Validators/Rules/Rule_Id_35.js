/**
 * Rule 36: BS chỉ định thuốc ung thư không đúng phạm vi chuyên môn
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const Doctor = require('../../Repos/Models/Doctor');

const validateRule_Id_35 = async (patientData) => {
    const result = {
        ruleName: 'BS chỉ định thuốc ung thư không đúng phạm vi chuyên môn',
        ruleId: 'Rule_Id_35',
        isValid: true,
        validateField: 'Ma_Thuoc',
        validateFile:'XML2',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml2_data = patientData.Xml2 || [];
        const dsThuocUngThu = [
            '40.339',
            '40.347',
            '40.359.2',
            '40.367',
            '40.369',
            '40.393'
        ];

        // Lấy danh sách mã bác sĩ có PHAMVI_CM là 112
        const dsBsiUngThu = await Doctor.find({ PHAMVI_CM: 112 });
        const maBacSiUngThu = dsBsiUngThu.map(bs => bs.MA_BAC_SI);

        xml2_data.forEach(item => {
            if (dsThuocUngThu.includes(item.Ma_Thuoc)) {
                // Nếu MA_BAC_SI không nằm trong danh sách bác sĩ ung thư thì báo lỗi
                if (!maBacSiUngThu.includes(item.MA_BAC_SI)) {
                    result.errors.push({
                       Id: item.Id,
                        Error: `Bác sĩ chỉ định thuốc ung thư (${item.Ma_Thuoc}) không đúng phạm vi chuyên môn (MA_BAC_SI: ${item.MA_BAC_SI})`
                    });
                    result.isValid = false;
                }
            }
        });

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate BS chỉ định thuốc ung thư không đúng phạm vi chuyên môn: ${error.message}`);
        result.message = 'Lỗi khi validate BS chỉ định thuốc ung thư không đúng phạm vi chuyên môn';
    }

    return result;
};

module.exports = validateRule_Id_35;