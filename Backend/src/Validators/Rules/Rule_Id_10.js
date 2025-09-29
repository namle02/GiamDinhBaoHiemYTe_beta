/**
 * Rule 10: Thanh toán “Xét nghiệm sinh thiết tức thì bằng cắt lạnh” không đúng quy định tại Quyết định số 3338/QĐ-BYT quy trình kỹ thuật khám bệnh, chữa bệnh chuyên ngành Ung bướu và Quyết định số 5199/QĐ-BYT quy trình kỹ thuật chuyênngành Giải phẫu bệnh - tế bào học.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_10 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán “Xét nghiệm sinh thiết tức thì bằng cắt lạnh” không đúng quy định tại Quyết định số 3338/QĐ-BYT quy trình kỹ thuật khám bệnh, chữa bệnh chuyên ngành Ung bướu và Quyết định số 5199/QĐ-BYT quy trình kỹ thuật chuyênngành Giải phẫu bệnh - tế bào học.',
        ruleId: 'Rule_Id_10',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        for (const item of patientData.Xml3) {
            const Ma_Dich_Vu = item.Ma_Dich_Vu;
            const Ma_Benh = item.Ma_Benh;

            if (Ma_Dich_Vu === '25.0090.1757') {
                // Tạo danh sách mã bệnh từ C00 đến C97
                let coMaBenhUngThu = false;
                for (let i = 0; i <= 97; i++) {
                    const code = i < 10 ? `C0${i}` : `C${i}`;
                    if (Ma_Benh && Ma_Benh.includes(code)) {
                        coMaBenhUngThu = true;
                        break;
                    }
                }
                if (!coMaBenhUngThu) {
                    result.isValid = false;
                    result.errors.push({ Id: item.Id, Error: 'Mã bệnh chính và bệnh kèm theo cần có từ C00 đến C97, không thanh toán "Xét nghiệm sinh thiết tức thì bằng cắt lạnh"' });
                }
            }
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi kiểm tra mã bệnh cho dịch vụ "Xét nghiệm sinh thiết tức thì bằng cắt lạnh": ${error.message}`);
        result.message = 'Lỗi khi validate dịch vụ "Xét nghiệm sinh thiết tức thì bằng cắt lạnh"';
    }

    return result;
};

module.exports = validateRule_Id_10;