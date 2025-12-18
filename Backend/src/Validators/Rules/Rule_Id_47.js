/**
 * Rule 47: Dịch vụ HbA1c thanh toán không đúng khoảng cách
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_47 = async (patientData) => {
    const result = {
        ruleName: 'Dịch vụ HbA1c thanh toán không đúng khoảng cách',
        ruleId: 'Rule_Id_47',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        
        // Hàm lấy phần ngày từ Ngay_Yl (dạng yyyyMMddHHmm - 14 ký tự)
        // Trả về yyyyMMdd (8 ký tự đầu)
        function getNgayFromNgayYl(ngayYl) {
            if (!ngayYl) return null;
            const ngayStr = String(ngayYl).trim();
            // Lấy 8 ký tự đầu (yyyyMMdd)
            return ngayStr.length >= 8 ? ngayStr.substring(0, 8) : null;
        }

        // Hàm chuyển đổi yyyyMMdd sang Date object
        function parseDate(ngayStr) {
            if (!ngayStr || ngayStr.length < 8) return null;
            const year = parseInt(ngayStr.substring(0, 4), 10);
            const month = parseInt(ngayStr.substring(4, 6), 10) - 1; // Month is 0-indexed
            const day = parseInt(ngayStr.substring(6, 8), 10);
            return new Date(year, month, day);
        }

        // Hàm tính khoảng cách giữa 2 ngày (số ngày)
        function tinhKhoangCachNgay(ngay1, ngay2) {
            const date1 = parseDate(ngay1);
            const date2 = parseDate(ngay2);
            if (!date1 || !date2) return null;
            const diffTime = Math.abs(date2 - date1);
            return Math.floor(diffTime / (1000 * 60 * 60 * 24));
        }

        // Lọc tất cả dịch vụ có Ma_Dich_Vu = "23.0083.1523"
        const dsHbA1c = xml3_data.filter(item => 
            item.Ma_Dich_Vu === '23.0083.1523' && item.Ngay_Yl
        );

        // Nếu không có dịch vụ HbA1c hoặc chỉ có 1 dịch vụ thì không cần kiểm tra
        if (dsHbA1c.length <= 1) {
            return result;
        }

        // Sắp xếp theo Ngay_Yl (tăng dần)
        dsHbA1c.sort((a, b) => {
            const ngayA = getNgayFromNgayYl(a.Ngay_Yl);
            const ngayB = getNgayFromNgayYl(b.Ngay_Yl);
            if (!ngayA || !ngayB) return 0;
            return ngayA.localeCompare(ngayB);
        });

        // Kiểm tra khoảng cách giữa các ngày liên tiếp
        for (let i = 0; i < dsHbA1c.length - 1; i++) {
            const ngayYl1 = getNgayFromNgayYl(dsHbA1c[i].Ngay_Yl);
            const ngayYl2 = getNgayFromNgayYl(dsHbA1c[i + 1].Ngay_Yl);

            if (!ngayYl1 || !ngayYl2) {
                continue;
            }

            const khoangCach = tinhKhoangCachNgay(ngayYl1, ngayYl2);

            if (khoangCach !== null && khoangCach < 87) {
                result.isValid = false;
                // Thêm lỗi cho cả 2 dịch vụ được so sánh
                result.errors.push({
                    Id: dsHbA1c[i].Id,
                    Error: `Khoảng cách giữa 2 lần xét nghiệm HbA1c (${khoangCach} ngày) nhỏ hơn 87 ngày. Ngày: ${ngayYl1}`
                });
                result.errors.push({
                    Id: dsHbA1c[i + 1].Id,
                    Error: `Khoảng cách giữa 2 lần xét nghiệm HbA1c (${khoangCach} ngày) nhỏ hơn 87 ngày. Ngày: ${ngayYl2}`
                });
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Dịch vụ HbA1c thanh toán không đúng khoảng cách: ${error.message}`);
        result.message = 'Lỗi khi validate Dịch vụ HbA1c thanh toán không đúng khoảng cách';
    }

    return result;
};

module.exports = validateRule_Id_47;

