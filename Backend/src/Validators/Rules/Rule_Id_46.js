/**
 * Rule 46: Holter điện tâm đồ hoặc lập trình máy tạo nhịp tim không được chỉ định đồng thời cùng điện tim
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_46 = async (patientData) => {
    const result = {
        ruleName: 'Holter điện tâm đồ hoặc lập trình máy tạo nhịp tim không được chỉ định đồng thời cùng điện tim',
        ruleId: 'Rule_Id_46',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        
        // Danh sách mã dịch vụ Holter hoặc Lập trình máy tạo nhịp tim
        const dsDichVuHolter = [
            '02.0095.1798',  // Holter điện tâm đồ
            '02.0100.0069'   // Lập trình máy tạo nhịp tim
        ];

        // Danh sách mã dịch vụ điện tim không được chỉ định đồng thời
        const dsDichVuDienTim = [
            '21.0014.1778',  // Điện tim thường
            '01.0002.1778',  // Ghi điện tim cấp cứu tại giường
            '02.0085.1778',  // Điện tim thường
            '03.0044.1778'   // Ghi điện tim cấp cứu tại giường
        ];

        // Lọc các dịch vụ Holter/Lập trình máy tạo nhịp tim
        const dsHolter = xml3_data.filter(item => 
            item.Ma_Dich_Vu && dsDichVuHolter.includes(item.Ma_Dich_Vu) && item.Ngay_Yl
        );

        // Lọc các dịch vụ điện tim
        const dsDienTim = xml3_data.filter(item => 
            item.Ma_Dich_Vu && dsDichVuDienTim.includes(item.Ma_Dich_Vu) && item.Ngay_Yl
        );

        // Nếu không có dịch vụ nào thì bỏ qua
        if (dsHolter.length === 0 || dsDienTim.length === 0) {
            return result;
        }

        // Kiểm tra từng dịch vụ Holter/Lập trình máy tạo nhịp tim
        dsHolter.forEach(itemHolter => {
            const ngayYlHolter = String(itemHolter.Ngay_Yl).trim();
            
            // Tìm các dịch vụ điện tim có cùng Ngay_Yl (chính xác, không bỏ phút)
            const dsDienTimTrung = dsDienTim.filter(itemDienTim => {
                const ngayYlDienTim = String(itemDienTim.Ngay_Yl).trim();
                return ngayYlDienTim === ngayYlHolter;
            });

            // Nếu có dịch vụ điện tim cùng Ngay_Yl → LỖI
            if (dsDienTimTrung.length > 0) {
                result.isValid = false;
                
                // Thêm lỗi cho dịch vụ Holter/Lập trình máy tạo nhịp tim
                result.errors.push({
                    Id: itemHolter.Id,
                    Error: `Dịch vụ ${itemHolter.Ma_Dich_Vu} không được chỉ định đồng thời với điện tim trong cùng thời điểm (Ngay_Yl: ${ngayYlHolter})`
                });

                // Thêm lỗi cho tất cả các dịch vụ điện tim trùng
                dsDienTimTrung.forEach(itemDienTim => {
                    result.errors.push({
                        Id: itemDienTim.Id,
                        Error: `Dịch vụ ${itemDienTim.Ma_Dich_Vu} không được chỉ định đồng thời với Holter/Lập trình máy tạo nhịp tim trong cùng thời điểm (Ngay_Yl: ${ngayYlHolter})`
                    });
                });
            }
        });

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Holter điện tâm đồ hoặc lập trình máy tạo nhịp tim không được chỉ định đồng thời cùng điện tim: ${error.message}`);
        result.message = 'Lỗi khi validate Holter điện tâm đồ hoặc lập trình máy tạo nhịp tim không được chỉ định đồng thời cùng điện tim';
    }

    return result;
};

module.exports = validateRule_Id_46;


