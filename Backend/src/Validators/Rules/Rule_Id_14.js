/**
 * Rule 14: Không thanh toán dịch vụ “thay băng vết mổ có chiều dài trên 15cm đến 30cm” lần thứ 4 trở đi đối với các trường hợp phẫu thuật mổ lấy thai, điểm d khoản 4 Điều 4d Thông tư số 39/2024/TT- BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_14 = async (patientData) => {
    const result = {
        ruleName: 'Không thanh toán dịch vụ “thay băng vết mổ có chiều dài trên 15cm đến 30cm” lần thứ 4 trở đi đối với các trường hợp phẫu thuật mổ lấy thai, điểm d khoản 4 Điều 4d Thông tư số 39/2024/TT- BYT',
        ruleId: 'Rule_Id_14',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;

        const itemsDichVu = (xml3_data || []).filter(it => it && it.Ma_Dich_Vu === '15.0303.2047');
        if (itemsDichVu.length > 3) {
            result.isValid = false;
            // Ghi lỗi cho từ lần thứ 4 trở đi
            itemsDichVu.slice(3).forEach(it => {
                result.errors.push({ Id: it.id || it.Id, Error: 'Không thanh toán dịch vụ “thay băng vết mổ có chiều dài trên 15cm đến 30cm” từ lần thứ 4 trở đi đối với mổ lấy thai (điểm d khoản 4 Điều 4d Thông tư 39/2024/TT-BYT)' });
            });
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Không thanh toán dịch vụ “thay băng vết mổ có chiều dài trên 15cm đến 30cm” lần thứ 4 trở đi đối với các trường hợp phẫu thuật mổ lấy thai, điểm d khoản 4 Điều 4d Thông tư số 39/2024/TT- BYT: ${error.message}`);
        result.message = 'Lỗi khi validate Không thanh toán dịch vụ “thay băng vết mổ có chiều dài trên 15cm đến 30cm” lần thứ 4 trở đi đối với các trường hợp phẫu thuật mổ lấy thai, điểm d khoản 4 Điều 4d Thông tư số 39/2024/TT- BYT';
    }

    return result;
};

module.exports = validateRule_Id_14;