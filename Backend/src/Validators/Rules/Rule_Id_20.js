/**
 * Rule 20: Thanh toán Oxy khi thanh toán đồng thời với dịch vụ thở máy do đã kết cấu chi phí Oxy trong giá dịch vụ, không đúng điểm c khoản 2 Điều 3 Thông tư số 22/2023/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_20 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán Oxy khi thanh toán đồng thời với dịch vụ thở máy do đã kết cấu chi phí Oxy trong giá dịch vụ, không đúng điểm c khoản 2 Điều 3 Thông tư số 22/2023/TT-BYT',
        ruleId: 'Rule_Id_20',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        const dsThoMay = new Set(['28.0016','28.0018','28.0130']); // ví dụ các mã dịch vụ thở máy
        const dsOxy = new Set(['28.0002','28.0003']); // ví dụ các mã Oxy

        const coThoMay = xml3_data.some(it => dsThoMay.has(String(it.Ma_Dich_Vu).trim()));
        if (!coThoMay) return result;

        xml3_data.forEach(it => {
            if (dsOxy.has(String(it.Ma_Dich_Vu).trim())) {
                result.isValid = false;
                result.errors.push({ Id: it.Id, Error: 'Không thanh toán Oxy đồng thời với dịch vụ thở máy (TT 22/2023/TT-BYT)' });
            }
        });
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán Oxy khi thanh toán đồng thời với dịch vụ thở máy do đã kết cấu chi phí Oxy trong giá dịch vụ, không đúng điểm c khoản 2 Điều 3 Thông tư số 22/2023/TT-BYT: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán Oxy khi thanh toán đồng thời với dịch vụ thở máy do đã kết cấu chi phí Oxy trong giá dịch vụ, không đúng điểm c khoản 2 Điều 3 Thông tư số 22/2023/TT-BYT';
    }

    return result;
};

module.exports = validateRule_Id_20;