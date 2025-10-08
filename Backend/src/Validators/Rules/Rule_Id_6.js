/**
 * Rule 6: Thanh toán dịch vụ “Bơm thông lệ đạo” đối với người bệnh không có bệnh chít hẹp điểm lệ, tắc lệ quản ngang hoặc ống lệ mũi.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_6 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ “Bơm thông lệ đạo” đối với người bệnh không có bệnh chít hẹp điểm lệ, tắc lệ quản ngang hoặc ống lệ mũi.',
        ruleId: 'Rule_Id_6',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;
        for (const item of xml3_data) {
            const Ma_Dich_Vu = item.Ma_Dich_Vu;
            const Ma_Benh = item.Ma_Benh;

            if (Ma_Dich_Vu === '14.0197.0854' || Ma_Dich_Vu === '14.0197.0855') {
               
               if (!Ma_Benh.includes('H04.2') && !Ma_Benh.includes('H04.3') && !Ma_Benh.includes('H04.4')) {
                    result.isValid = false;
                    result.errors.push({ Id: item.Id, Error: 'Mã bệnh chính và bệnh kèm theo cần có H04.2, H04.3, H04.4' });
                }
            }

        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ “Bơm thông lệ đạo” đối với người bệnh không có bệnh chít hẹp điểm lệ, tắc lệ quản ngang hoặc ống lệ mũi: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ “Bơm thông lệ đạo” đối với người bệnh không có bệnh chít hẹp điểm lệ, tắc lệ quản ngang hoặc ống lệ mũi';
    }

    return result;
};

module.exports = validateRule_Id_6;