/**
 * Rule 28: Thanh toán thuốc Alphachymotrypsin chỉ định sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_28 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán thuốc Alphachymotrypsin chỉ định sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT',
        ruleId: 'Rule_Id_28',
        isValid: true,
        validateField: 'Ma_Thuoc',
        validateFile:'XML2',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách thuốc từ XML2
        const dsThuoc = Array.isArray(patientData.Xml2) ? patientData.Xml2 : [];
        // Lấy danh sách mã bệnh từ XML1 (ưu tiên Ma_Benh_Chinh, Ma_Benh_Kt, Ma_Benh_Yhct)
        let dsMaBenh = [];
        const xml1_data = patientData.Xml1[0] || {};

        if (xml1_data.Ma_Benh_Kt) {
            if (typeof xml1_data.Ma_Benh_Kt == 'string') {
                dsMaBenh = xml1_data.Ma_Benh_Kt.split(';').map(s => s.trim().toUpperCase()).filter(Boolean);
            } else if (Array.isArray(xml1_data.Ma_Benh_Kt)) {
                dsMaBenh = xml1_data.Ma_Benh_Kt.flatMap(mb => (typeof mb === 'string' ? mb.split(';').map(s => s.trim().toUpperCase()) : [])).filter(Boolean);
            }
        }
        if (xml1_data.Ma_Benh_Yhct) {
            if (typeof xml1_data.Ma_Benh_Yhct == 'string') {
                dsMaBenh = xml1_data.Ma_Benh_Yhct.split(';').map(s => s.trim().toUpperCase()).filter(Boolean);
            } else if (Array.isArray(xml1_data.Ma_Benh_Yhct)) {
                dsMaBenh = xml1_data.Ma_Benh_Yhct.flatMap(mb => (typeof mb === 'string' ? mb.split(';').map(s => s.trim().toUpperCase()) : [])).filter(Boolean);
            }
        }

        dsMaBenh = Array.from(new Set(dsMaBenh)); // loại trùng

        // Thêm trực tiếp xml1_data.Ma_Benh_Chinh vào dsMaBenh
        dsMaBenh.push(xml1_data.Ma_Benh_Chinh.toUpperCase());

        // Các mã bệnh hợp lệ
        const maBenhDung = [
            // Cụm J00-J06
            { type: 'range', from: 'J00', to: 'J06' },
            // J20
            { type: 'exact', code: 'J20' },
            // T14.x
            { type: 'prefix', code: 'T14' },
            // S00-S09
            { type: 'range', from: 'S00', to: 'S09' },
            // S10-S19
            { type: 'range', from: 'S10', to: 'S19' },
            // S40-S49
            { type: 'range', from: 'S40', to: 'S49' },
            // S50-S59
            { type: 'range', from: 'S50', to: 'S59' },
            // S60-S69
            { type: 'range', from: 'S60', to: 'S69' },
            // S70-S79
            { type: 'range', from: 'S70', to: 'S79' },
            // S80-S89
            { type: 'range', from: 'S80', to: 'S89' },
            // S90-S99
            { type: 'range', from: 'S90', to: 'S99' },
        ];

        // Hàm kiểm tra mã bệnh có hợp lệ không
        function isMaBenhHopLe(ma) {
            // Chuẩn hóa mã bệnh
            ma = ma.toUpperCase().replace(/\s/g, '');
            for (const rule of maBenhDung) {
                if (rule.type === 'exact' && ma === rule.code) return true;
                if (rule.type === 'prefix' && ma.startsWith(rule.code)) return true;
                if (rule.type === 'range') {
                    // So sánh ký tự đầu và số
                    const prefix = rule.from.slice(0, 1);
                    if (ma.startsWith(prefix)) {
                        // Lấy số phần sau
                        const soMa = parseInt(ma.slice(1, 3), 10);
                        const soFrom = parseInt(rule.from.slice(1, 3), 10);
                        const soTo = parseInt(rule.to.slice(1, 3), 10);
                        if (!isNaN(soMa) && soMa >= soFrom && soMa <= soTo) {
                            return true;
                        }
                    }
                }
            }
            return false;
        }

        // Duyệt từng thuốc, nếu Ma_Thuoc là 40.67 thì kiểm tra mã bệnh
        dsThuoc.forEach((thuoc, idx) => {
            if ((thuoc.Ma_Thuoc || thuoc.Ma_Thuoc === 0) && String(thuoc.Ma_Thuoc).trim() === '40.67') {
                // Kiểm tra có mã bệnh hợp lệ không
                const coMaBenhHopLe = dsMaBenh.some(isMaBenhHopLe);
                if (!coMaBenhHopLe) {
                    result.isValid = false;
                    result.errors.push({ Id: thuoc.Id, Error: 'Alphachymotrypsin (40.67) không có mã bệnh phù hợp theo quy định' });
                }
            }
        });

        if (!result.isValid && result.errors.length > 0) {
            result.message = result.errors.join('; ');
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán thuốc Alphachymotrypsin chỉ định sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán thuốc Alphachymotrypsin chỉ định sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT';
    }

    return result;
};

module.exports = validateRule_Id_28;