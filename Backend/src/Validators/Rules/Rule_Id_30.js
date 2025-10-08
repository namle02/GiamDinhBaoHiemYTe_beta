/**
 * Rule 30: Thanh toán các thuốc chứa hoạt chất "Omeprazol mã chi phí (40.677); Esomeprazol mã chi phí (40.678); Pantoprazol mã chi phí (40.679); Rabeprazol mã chi phí (40.680) không đúng quy định tại Thông tư số 20/2022/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_30 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán các thuốc chứa hoạt chất "Omeprazol mã chi phí (40.677); Esomeprazol mã chi phí (40.678); Pantoprazol mã chi phí (40.679); Rabeprazol mã chi phí (40.680) không đúng quy định tại Thông tư số 20/2022/TT-BYT',
        ruleId: 'Rule_Id_30',
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

        // Danh sách mã thuốc cần kiểm tra
        const dsMaThuocCheck = ['40.677', '40.678', '40.679', '40.680'];

        // Danh sách mã bệnh hợp lệ
        const regexMaBenh = [
            /^K25\.\d*$/i, // Viêm loét dạ dày – tá tràng
            /^K26\.\d*$/i,
            /^K27\.\d*$/i,
            /^K28\.\d*$/i,
            /^K21\.\d*$/i, // Trào ngược dạ dày thực quản có biến chứng
            /^E16\.4$/i,   // Hội chứng Zollinger-Ellison
            /^K20\.\d*$/i  // Viêm thực quản nặng, Barrett thực quản
        ];

        // Kiểm tra từng thuốc, nếu có thuốc thuộc nhóm cần kiểm tra thì phải có mã bệnh hợp lệ
        dsThuoc.forEach((thuoc, idx) => {
            if ((thuoc.Ma_Thuoc || thuoc.Ma_Thuoc === 0) && dsMaThuocCheck.includes(String(thuoc.Ma_Thuoc).trim())) {
                // Kiểm tra có mã bệnh hợp lệ không
                const coMaBenhHopLe = dsMaBenh.some(ma => regexMaBenh.some(regex => regex.test(ma)));
                if (!coMaBenhHopLe) {
                    result.isValid = false;
                    result.errors.push({ Id: thuoc.Id, Error: 'PPI (40.677/40.678/40.679/40.680) chỉ thanh toán với K25.x/K26.x/K27.x/K28.x/K21.x/E16.4/K20.x' });
                }
            }
        });

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán các thuốc chứa hoạt chất "Omeprazol mã chi phí (40.677); Esomeprazol mã chi phí (40.678); Pantoprazol mã chi phí (40.679); Rabeprazol mã chi phí (40.680) không đúng quy định tại Thông tư số 20/2022/TT-BYT: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán các thuốc chứa hoạt chất "Omeprazol mã chi phí (40.677); Esomeprazol mã chi phí (40.678); Pantoprazol mã chi phí (40.679); Rabeprazol mã chi phí (40.680) không đúng quy định tại Thông tư số 20/2022/TT-BYT';
    }

    return result;
};

module.exports = validateRule_Id_30;