/**
 * Rule 1: Thanh toán dịch vụ PHCN trong điều trị thoái hóa cột sống cổ/cột sống thắt lưng: Hồng ngoại, đắp paraphin, ...không đúng hướng dẫn tại Quyết định số 3109/QĐ-BYT chẩn đoán, điều trị chuyên ngành PHCN
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_7 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ PHCN trong điều trị thoái hóa cột sống cổ/cột sống thắt lưng: Hồng ngoại, đắp paraphin, ...không đúng hướng dẫn tại Quyết định số 3109/QĐ-BYT chẩn đoán, điều trị chuyên ngành PHCN',
        ruleId: 'Rule_Id_7',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách dịch vụ từ Xml3
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        // Danh sách mã dịch vụ PHCN cần kiểm tra
        const danhsachdichvu = [
            '17.0007.0234',
            '17.0009.0255',
            '17.0018.0221',
            '17.0026.0220',
            '17.0011.0237',
            '17.0001.0254',
            '17.0004.0232'
        ];

        // Regex các mã bệnh hợp lệ
        const regexMaBenh = [
            /^I6[0-9](\.\d+)?$/i,      // I60-I69 – Tai biến mạch máu não
            /^G8[1-3](\.\d+)?$/i,      // G81-G83 – Liệt nửa người, liệt tay chân
            /^S52(\.\d+)?$/i,          // S52 – Gãy xương chi
            /^S62(\.\d+)?$/i,          // S62 – Gãy xương chi
            /^S72(\.\d+)?$/i,          // S72 – Gãy xương chi
            /^S82(\.\d+)?$/i,          // S82 – Gãy xương chi
            /^M51(\.\d+)?$/i,          // M51 – Thoát vị đĩa đệm, thoái hóa cột sống
            /^M48(\.\d+)?$/i,          // M48 – Thoát vị đĩa đệm, thoái hóa cột sống
            /^M50(\.\d+)?$/i,          // M50 – Thoát vị đĩa đệm, thoái hóa cột sống
            /^M54(\.\d+)?$/i,          // M54 – Đau cột sống
            /^G35(\.\d+)?$/i           // G35 – Đa xơ cứng
        ];

        // Hàm kiểm tra mã bệnh hợp lệ
        function isMaBenhHopLe(ma) {
            if (!ma) return false;
            ma = ma.toUpperCase().replace(/\s/g, '');
            return regexMaBenh.some(regex => regex.test(ma));
        }

        // Duyệt từng dịch vụ trong xml3, nếu là dịch vụ PHCN thì kiểm tra mã bệnh trong chính record đó
        xml3_data.forEach(item => {
            if (danhsachdichvu.includes(item.Ma_Dich_Vu)) {
                // Mã bệnh có thể nằm ở Ma_Benh hoặc Ma_Benh_Yhct trong từng item của xml3
                let dsMaBenh = [];
                if (item.Ma_Benh) {
                    dsMaBenh.push(item.Ma_Benh.toUpperCase());
                }
                if (item.Ma_Benh_Yhct) {
                    dsMaBenh.push(item.Ma_Benh_Yhct.toUpperCase());
                }

                dsMaBenh = Array.from(new Set(dsMaBenh)); // loại trùng

                const coMaBenhHopLe = dsMaBenh.some(isMaBenhHopLe);

                if (!coMaBenhHopLe) {
                    result.isValid = false;
                    result.errors.push(
                        { Id: item.Id, Error: `Dịch vụ PHCN mã ${item.Ma_Dich_Vu} thanh toán sai mã bệnh: ${item.Ma_Benh}` }
                    );
                }
            }
        });

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ PHCN trong điều trị thoái hóa cột sống cổ/cột sống thắt lưng: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ PHCN trong điều trị thoái hóa cột sống cổ/cột sống thắt lưng';
    }

    return result;
};

module.exports = validateRule_Id_7;