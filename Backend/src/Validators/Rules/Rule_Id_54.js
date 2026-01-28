/**
 * Rule 54: Thuốc cản quang đã nằm trong cơ cấu giá MRI, XQ
 * Kiểm tra nếu có thuốc cản quang và dịch vụ MRI/X-quang thì báo lỗi
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_54 = async (patientData) => {
    const result = {
        ruleName: 'Thuốc cản quang đã nằm trong cơ cấu giá MRI, XQ',
        ruleId: 'Rule_Id_54',
        isValid: true,
        validateField: 'Ma_Thuoc',
        validateFile: 'XML2',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách thuốc từ Xml2
        const dsThuoc = Array.isArray(patientData.Xml2) ? patientData.Xml2 : [];
        
        // Lấy danh sách dịch vụ từ Xml3
        const dsDichVu = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];

        if (dsThuoc.length === 0 || dsDichVu.length === 0) {
            return result;
        }

        // ============================================
        // DANH SÁCH MÃ THUỐC CẢN QUANG
        // ============================================
        const danhSachMaThuocCanQuang = [
            '40.637',
            '40.641',
            '40.634'
        ];

        // ============================================
        // DANH SÁCH CÁC TỪ KHÓA TRONG TÊN DỊCH VỤ (không phân biệt hoa thường)
        // ============================================
        const cumTuCanTim = [
            'cộng hưởng từ',
            'X-quang'
        ];

        // Hàm kiểm tra tên dịch vụ có chứa các cụm từ cần tìm
        const kiemTraTenDichVu = (tenDichVu) => {
            if (!tenDichVu || typeof tenDichVu !== 'string') {
                return false;
            }
            const tenDichVuLower = tenDichVu.toLowerCase().trim();
            return cumTuCanTim.some(cumTu => tenDichVuLower.includes(cumTu.toLowerCase()));
        };

        // Lọc các thuốc cản quang
        const dsThuocCanQuang = dsThuoc.filter(thuoc => {
            const maThuoc = thuoc.Ma_Thuoc || thuoc.Ma_thuoc;
            return maThuoc && danhSachMaThuocCanQuang.includes(maThuoc);
        });

        // Lọc các dịch vụ có tên chứa "cộng hưởng từ" hoặc "X-quang"
        const dsDichVuMRIXQ = dsDichVu.filter(dv => {
            const tenDichVu = dv.Ten_Dich_Vu || dv.ten_Dich_Vu || '';
            return kiemTraTenDichVu(tenDichVu);
        });

        // Nếu có cả thuốc cản quang và dịch vụ MRI/X-quang thì báo lỗi
        if (dsThuocCanQuang.length > 0 && dsDichVuMRIXQ.length > 0) {
            result.isValid = false;

            // Báo lỗi cho các thuốc cản quang
            dsThuocCanQuang.forEach(thuoc => {
                const danhSachTenDichVu = dsDichVuMRIXQ.map(dv => dv.Ten_Dich_Vu || 'N/A').join(', ');
                result.errors.push({
                    Id: thuoc.id || thuoc.Id,
                    Error: `Thuốc cản quang (${thuoc.Ma_Thuoc || thuoc.Ma_thuoc}) đã nằm trong cơ cấu giá của dịch vụ: ${danhSachTenDichVu}`
                });
            });

            // Báo lỗi cho các dịch vụ MRI/X-quang
            dsDichVuMRIXQ.forEach(dv => {
                const danhSachMaThuoc = dsThuocCanQuang.map(t => t.Ma_Thuoc || t.Ma_thuoc).join(', ');
                result.errors.push({
                    Id: dv.id || dv.Id,
                    Error: `Dịch vụ ${dv.Ten_Dich_Vu || 'N/A'} (${dv.Ma_Dich_Vu || 'N/A'}) đã bao gồm thuốc cản quang trong cơ cấu giá: ${danhSachMaThuoc}`
                });
            });
        }

        if (result.errors.length > 0) {
            result.message = 'Thuốc cản quang đã nằm trong cơ cấu giá MRI, X-quang';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thuốc cản quang đã nằm trong cơ cấu giá MRI, XQ: ${error.message}`);
        result.message = 'Lỗi khi validate Thuốc cản quang đã nằm trong cơ cấu giá MRI, XQ';
    }

    return result;
};

module.exports = validateRule_Id_54;
