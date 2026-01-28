/**
 * Rule 52: Thanh toán bơm tiêm, kim luồn không có thuốc đường dùng tiêm truyền
 * Kiểm tra nếu có dịch vụ bơm tiêm hoặc kim luồn thì phải có thuốc đường dùng tiêm truyền
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_52 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán bơm tiêm, kim luồn không có thuốc đường dùng tiêm truyền',
        ruleId: 'Rule_Id_52',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile: 'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách dịch vụ từ Xml3
        const dsDichVu = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        
        // Lấy danh sách thuốc từ Xml2
        const dsThuoc = Array.isArray(patientData.Xml2) ? patientData.Xml2 : [];

        if (dsDichVu.length === 0) {
            return result;
        }

        // ============================================
        // DANH SÁCH MÃ DỊCH VỤ BƠM TIÊM
        // ============================================
        const danhSachBomTiem = [
            'N03.01.070.1024.000.0002',
            'N03.01.070.1024.000.0001',
            'N03.01.070.1024.000.0003',
            'N03.01.070.1024.000.0012'
        ];

        // ============================================
        // DANH SÁCH MÃ DỊCH VỤ KIM LUỒN
        // ============================================
        const danhSachKimLuon = [
            'N03.05.010.5327.279.0001',
            'N03.02.070.0337.205.0012',
            'N03.02.070.4390.115.0001'
        ];

        // ============================================
        // DANH SÁCH MÃ THUỐC ĐƯỜNG DÙNG TIÊM TRUYỀN
        // ============================================
        const danhSachMaThuocTiemTruyen = [
            '40.806',
            '40.391',
            '40.983',
            '40.105',
            '40P.52',
            '40.891',
            '40.358',
            '40.217'
        ];

        // Gộp danh sách bơm tiêm và kim luồn
        const danhSachDichVuCanCheck = [...danhSachBomTiem, ...danhSachKimLuon];

        // Lấy danh sách mã thuốc tiêm truyền có trong XML2
        const dsMaThuocTiemTruyen = dsThuoc
            .map(thuoc => thuoc.Ma_Thuoc || thuoc.Ma_thuoc)
            .filter(ma => ma && danhSachMaThuocTiemTruyen.includes(ma));

        // Kiểm tra từng dịch vụ trong XML3
        dsDichVu.forEach(dv => {
            const maDichVu = dv.Ma_Dich_Vu;
            
            // Kiểm tra xem Ma_Dich_Vu có thuộc danh sách bơm tiêm/kim luồn không
            if (!maDichVu || !danhSachDichVuCanCheck.includes(maDichVu)) {
                return; // Bỏ qua nếu không thuộc danh sách cần check
            }

            // Kiểm tra xem có thuốc tiêm truyền trong XML2 không
            if (dsMaThuocTiemTruyen.length === 0) {
                result.isValid = false;
                result.errors.push({
                    Id: dv.id || dv.Id,
                    Error: `Dịch vụ ${maDichVu} (bơm tiêm/kim luồn) không có thuốc đường dùng tiêm truyền trong danh sách thuốc`
                });
            }
        });

        if (result.errors.length > 0) {
            result.message = 'Có dịch vụ bơm tiêm, kim luồn không có thuốc đường dùng tiêm truyền';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán bơm tiêm, kim luồn không có thuốc đường dùng tiêm truyền: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán bơm tiêm, kim luồn không có thuốc đường dùng tiêm truyền';
    }

    return result;
};

module.exports = validateRule_Id_52;
