/**
 * Rule 17: Thanh toán xét nghiệm AFB hơn 2 lần/ngày không đúng quy định tại Quyết định số 3126/QĐ-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

/**
 * Rule 17: Thanh toán xét nghiệm AFB hơn 2 lần/ngày không đúng quy định tại Quyết định số 3126/QĐ-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_17 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán xét nghiệm AFB không quá 2 lần/ngày theo Quyết định 3126/QĐ-BYT',
        ruleId: 'Rule_Id_17',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;
        const maDichVuAFB = '24.0017.1714';

        // Đếm số lần dịch vụ AFB theo từng ngày y lệnh
        const countByNgayYl = {};

        for (const item of xml3_data) {
            if (item.Ma_Dich_Vu === maDichVuAFB) {
                // Ngay_Yl có dạng 202501210722, chỉ lấy 8 ký tự đầu (yyyyMMdd)
                let ngayYl = item.Ngay_Yl ? item.Ngay_Yl.toString().substring(0, 8) : 'unknown';
                if (!countByNgayYl[ngayYl]) {
                    countByNgayYl[ngayYl] = 0;
                }
                countByNgayYl[ngayYl]++;
            }
        }

        // Kiểm tra nếu có ngày nào vượt quá 2 lần xét nghiệm AFB
        const ngayViPham = [];
        for (const [ngay, count] of Object.entries(countByNgayYl)) {
            if (count > 2) {
                ngayViPham.push(ngay);
            }
        }

        if (ngayViPham.length > 0) {
            result.isValid = false;
            // Ghi lỗi cho từng item thuộc các ngày vi phạm
            for (const item of xml3_data) {
                if (item.Ma_Dich_Vu === maDichVuAFB) {
                    const ngay = item.Ngay_Yl ? item.Ngay_Yl.toString().substring(0, 8) : 'unknown';
                    if (ngayViPham.includes(ngay)) {
                        result.errors.push({ Id: item.Id, Error: 'Xét nghiệm AFB vượt quá 2 lần/ngày theo Quyết định 3126/QĐ-BYT' });
                    }
                }
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi kiểm tra số lượng xét nghiệm AFB theo ngày: ${error.message}`);
        result.message = 'Lỗi khi validate số lượng xét nghiệm AFB theo ngày.';
    }

    return result;
};

module.exports = validateRule_Id_17;