/**
 * Rule 56: Đặt catheter không thanh toán thêm catheter
 * Kiểm tra dịch vụ đặt catheter không được thanh toán thêm vật tư catheter
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_56 = async (patientData) => {
    const result = {
        ruleName: 'Đặt catheter không thanh toán thêm catheter',
        ruleId: 'Rule_Id_56',
        isValid: true,
        validateField: 'Ma_Vat_Tu',
        validateFile: 'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách dịch vụ từ Xml3
        const dsDichVu = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];

        if (dsDichVu.length === 0) {
            return result;
        }

        // ============================================
        // DANH SÁCH MÃ DỊCH VỤ ĐẶT CATHETER
        // ============================================
        const danhSachMaDichVuDatCatheter = [
            '01.0009.0098', // Đặt catheter động mạch
            '01.0007.0099', // Đặt catheter tĩnh mạch trung tâm 1 nòng
            '01.0317.0099', // Đặt catheter tĩnh mạch trung tâm một nòng dưới hướng dẫn của siêu âm
            '01.0319.0100', // Đặt catheter tĩnh mạch trung tâm ba nòng dưới hướng dẫn của siêu âm
            '01.0318.0100', // Đặt catheter tĩnh mạch trung tâm hai nòng dưới hướng dẫn của siêu âm
            '01.0008.0100', // Đặt catheter tĩnh mạch trung tâm nhiều nòng
            '01.0172.0101', // Đặt catheter lọc máu cấp cứu
            '01.0006.0215', // Đặt catheter tĩnh mạch ngoại biên
            '01.0014.1774', // Đặt catheter động mạch phổi
            '02.0015.0071', // Đặt catheter qua màng nhẫn giáp lấy bệnh phẩm
            '02.0183.0100', // Đặt catheter tĩnh mạch cảnh để lọc máu cấp cứu
            '02.0185.0101', // Đặt catheter hai nòng tĩnh mạch cảnh trong để lọc máu
            '02.0186.0101', // Đặt catheter hai nòng tĩnh mạch dưới đòn để lọc máu
            '02.0498.0101', // Đặt catheter một nòng hoặc hai nòng tĩnh mạch đùi để lọc máu
            '02.0184.0102', // Đặt catheter hai nòng có cuff, tạo đường hầm để lọc máu
            '03.0033.0097', // Đặt catheter động mạch
            '03.0035.0099', // Đặt catheter tĩnh mạch trung tâm
            '03.0035.0100', // Đặt catheter tĩnh mạch trung tâm
            '03.0117.0101', // Đặt catheter lọc máu cấp cứu
            '03.0017.1774', // Đặt catheter động mạch phổi
            '11.0088.0099', // Đặt catheter tĩnh mạch trung tâm bù dịch điều trị sốc bỏng
            '09.0028.0099'  // Đặt catheter tĩnh mạch cảnh ngoài
        ];

        // ============================================
        // DANH SÁCH MÃ VẬT TƯ CATHETER
        // ============================================
        const danhSachMaVatTuCatheter = [
            'N04.04.010.3831.279.0002',
            'N04.04.020.4263.175.0001'
        ];

        // Kiểm tra từng dịch vụ trong XML3
        dsDichVu.forEach(dv => {
            const maDichVu = dv.Ma_Dich_Vu;
            const maVatTu = dv.Ma_Vat_Tu || dv.Ma_vat_tu;
            
            // Kiểm tra xem Ma_Dich_Vu có thuộc danh sách đặt catheter không
            if (!maDichVu || !danhSachMaDichVuDatCatheter.includes(maDichVu)) {
                return; // Bỏ qua nếu không thuộc danh sách đặt catheter
            }

            // Kiểm tra xem có Ma_vat_tu thuộc danh sách catheter không
            if (maVatTu && danhSachMaVatTuCatheter.includes(maVatTu)) {
                result.isValid = false;
                result.errors.push({
                    Id: dv.id || dv.Id,
                    Error: `Dịch vụ đặt catheter ${maDichVu} không được thanh toán thêm vật tư catheter ${maVatTu} (đã có trong cơ cấu giá dịch vụ)`
                });
            }
        });

        if (result.errors.length > 0) {
            result.message = 'Có dịch vụ đặt catheter thanh toán thêm vật tư catheter';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Đặt catheter không thanh toán thêm catheter: ${error.message}`);
        result.message = 'Lỗi khi validate Đặt catheter không thanh toán thêm catheter';
    }

    return result;
};

module.exports = validateRule_Id_56;
