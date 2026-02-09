/**
 * Rule 5: Thanh toán dịch vụ HbA1C (23.0083.1523) phải có mã ICD đái tháo đường E10–E14 trong XML3.Ma_Benh
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_5 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ HbA1C không có mã ICD đái tháo đường',
        ruleId: 'Rule_Id_5',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile: 'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;
        if (!Array.isArray(xml3_data)) return result;

        const MA_DV_HBA1C = '23.0083.1523';
        const maBenhDaThaiDuong = ['E10', 'E11', 'E12', 'E13', 'E14'];

        const coMaE10E14 = (maBenh) => {
            if (maBenh == null || typeof maBenh !== 'string') return false;
            const s = String(maBenh).trim().toUpperCase();
            return maBenhDaThaiDuong.some(code => s.includes(code));
        };

        for (const item of xml3_data) {
            const Ma_Dich_Vu = item.Ma_Dich_Vu;
            const Ma_Benh = item.Ma_Benh;

            if (Ma_Dich_Vu === MA_DV_HBA1C) {
                if (!coMaE10E14(Ma_Benh)) {
                    result.isValid = false;
                    result.errors.push({
                        Id: item.id ?? item.Id,
                        Error: 'Thanh toán dịch vụ HbA1C (23.0083.1523) nhưng XML3 không có mã bệnh đái tháo đường (E10–E14)'
                    });
                }
            }
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push({ Id: null, Error: `Lỗi khi validate Rule_Id_5: ${error.message}` });
        result.message = 'Lỗi khi validate HbA1C';
    }

    return result;
};

module.exports = validateRule_Id_5;
