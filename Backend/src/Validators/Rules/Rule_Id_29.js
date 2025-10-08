/**
 * Rule 29: Thanh toán thuốc có hoạt chất Sylimarin (mã thuốc 40.751): thuốc Silygamma, Carsil 90mg, Fynkhepar chỉ định sử dụng không phù hợp với chỉ định trong tờ hướng dẫn sử dụng
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_29 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán thuốc có hoạt chất Sylimarin (mã thuốc 40.751): thuốc Silygamma, Carsil 90mg, Fynkhepar chỉ định sử dụng không phù hợp với chỉ định trong tờ hướng dẫn sử dụng',
        ruleId: 'Rule_Id_29',
        isValid: true,
        validateField: 'Ma_Thuoc',
        validateFile:'XML2',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách thuốc từ Xml2
        const dsThuoc = Array.isArray(patientData.Xml2) ? patientData.Xml2 : [];
        // Lấy dữ liệu bệnh từ Xml1 (chỉ lấy phần tử đầu tiên)
        const xml1 = Array.isArray(patientData.Xml1) && patientData.Xml1.length > 0 ? patientData.Xml1[0] : {};

        // Lấy danh sách mã bệnh từ các trường
        let dsMaBenh = [];

        if (xml1.Ma_Benh_Kt) {
            if (typeof xml1.Ma_Benh_Kt === 'string') {
                dsMaBenh = dsMaBenh.concat(xml1.Ma_Benh_Kt.split(';').map(s => s.trim().toUpperCase()).filter(Boolean));
            } else if (Array.isArray(xml1.Ma_Benh_Kt)) {
                dsMaBenh = dsMaBenh.concat(
                    xml1.Ma_Benh_Kt.flatMap(mb => (typeof mb === 'string' ? mb.split(';').map(s => s.trim().toUpperCase()) : []))
                );
            }
        }
        if (xml1.Ma_Benh_Yhct) {
            if (typeof xml1.Ma_Benh_Yhct === 'string') {
                dsMaBenh = dsMaBenh.concat(xml1.Ma_Benh_Yhct.split(';').map(s => s.trim().toUpperCase()).filter(Boolean));
            } else if (Array.isArray(xml1.Ma_Benh_Yhct)) {
                dsMaBenh = dsMaBenh.concat(
                    xml1.Ma_Benh_Yhct.flatMap(mb => (typeof mb === 'string' ? mb.split(';').map(s => s.trim().toUpperCase()) : []))
                );
            }
        }
        if (xml1.Ma_Benh_Chinh) {
            dsMaBenh.push(String(xml1.Ma_Benh_Chinh).trim().toUpperCase());
        }

        dsMaBenh = Array.from(new Set(dsMaBenh)); // loại trùng

        // Danh sách mã bệnh hợp lệ
        const maBenhDung = [
            'B18.0', 'B18.1', 'B18.2', 'B18.8', 'K76.0', 'K76.9'
        ];
        // Regex cho K71.x, K74.x
        const regexK71 = /^K71\.\d*$/i;
        const regexK74 = /^K74\.\d*$/i;

        // Hàm kiểm tra mã bệnh hợp lệ
        function isMaBenhHopLe(ma) {
            if (!ma) return false;
            ma = ma.toUpperCase().replace(/\s/g, '');
            if (maBenhDung.includes(ma)) return true;
            if (regexK71.test(ma)) return true;
            if (regexK74.test(ma)) return true;
            return false;
        }

        // Duyệt từng thuốc, nếu Ma_Thuoc = 40.751 thì kiểm tra mã bệnh
        dsThuoc.forEach((thuoc, idx) => {
            if ((thuoc.Ma_Thuoc || thuoc.Ma_Thuoc === 0) && String(thuoc.Ma_Thuoc).trim() === '40.751') {
                // Kiểm tra có mã bệnh hợp lệ không
                const coMaBenhHopLe = dsMaBenh.some(isMaBenhHopLe);
                if (!coMaBenhHopLe) {
                    result.isValid = false;
                    result.errors.push({ Id: thuoc.Id, Error: 'Sylimarin (40.751) chỉ thanh toán khi có mã bệnh: B18.0/B18.1/B18.2/B18.8/K76.0/K76.9/K71.x/K74.x' });
                }
            }
        });

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán thuốc có hoạt chất Sylimarin (mã thuốc 40.751): thuốc Silygamma, Carsil 90mg, Fynkhepar chỉ định sử dụng không phù hợp với chỉ định trong tờ hướng dẫn sử dụng: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán thuốc có hoạt chất Sylimarin (mã thuốc 40.751): thuốc Silygamma, Carsil 90mg, Fynkhepar chỉ định sử dụng không phù hợp với chỉ định trong tờ hướng dẫn sử dụng';
    }

    return result;
};

module.exports = validateRule_Id_29;