/**
 * Rule 16: Thanh toán dịch vụ kỹ thuật vật lý trị liệu vượt quá số lượng quy định tại Thông tư số 50/2017/TT-BYT (các kỹ thuật vật lý trị liệu thanh toán tối đa 04 kỹ thuật/ngày)
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_16 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ kỹ thuật vật lý trị liệu vượt quá số lượng quy định tại Thông tư số 50/2017/TT-BYT (các kỹ thuật vật lý trị liệu thanh toán tối đa 04 kỹ thuật/ngày)',
        ruleId: 'Rule_Id_16',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;

        const danhsachdichvu = [
            '17.0007.0234', 
            '17.0009.0255',
            '17.0018.0221',
            '17.0026.0220',
            '17.0011.0237',
            '17.0001.0254',
            '17.0004.0232'
        ];

        // Tạo map để đếm số lượng dịch vụ vật lý trị liệu theo từng ngày (chỉ lấy phần ngày từ chuỗi Ngay_Yl)
        const countByNgayYl = {};

        for (const item of xml3_data) {
            if (danhsachdichvu.includes(item.Ma_Dich_Vu)) {
                // Ngay_Yl có dạng 202501210722, chỉ lấy 8 ký tự đầu (yyyyMMdd)
                let ngayYl = item.Ngay_Yl ? item.Ngay_Yl.toString().substring(0, 8) : 'unknown';
                if (!countByNgayYl[ngayYl]) {
                    countByNgayYl[ngayYl] = 0;
                }
                countByNgayYl[ngayYl]++;
            }
        }

        // Kiểm tra nếu có ngày nào vượt quá 4 dịch vụ vật lý trị liệu
        const ngayViPham = [];
        for (const [ngay, count] of Object.entries(countByNgayYl)) {
            if (count > 4) {
                ngayViPham.push(ngay);
            }
        }

        if (ngayViPham.length > 0) {
            result.isValid = false;
            for (const item of xml3_data) {
                if (danhsachdichvu.includes(item.Ma_Dich_Vu)) {
                    const ngay = item.Ngay_Yl ? item.Ngay_Yl.toString().substring(0, 8) : 'unknown';
                    if (ngayViPham.includes(ngay)) {
                        result.errors.push({ Id: item.id || item.Id, Error: 'Vật lý trị liệu vượt quá 04 kỹ thuật/ngày (TT 50/2017/TT-BYT)' });
                    }
                }
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi kiểm tra số lượng dịch vụ vật lý trị liệu theo ngày: ${error.message}`);
        result.message = 'Lỗi khi validate số lượng dịch vụ vật lý trị liệu theo ngày.';
    }

    return result;
};

module.exports = validateRule_Id_16;