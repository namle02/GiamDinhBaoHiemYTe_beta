/**
 * Rule 28: Thanh toán thuốc Alphachymotrypsin chỉ định sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_28 = async (patientData) => {
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
        if (xml1_data.Ma_Benh_Chinh) {
            const maBenhChinh = String(xml1_data.Ma_Benh_Chinh).trim().toUpperCase();
            if (maBenhChinh) {
                dsMaBenh.push(maBenhChinh);
            }
        }

        // Các mã bệnh hợp lệ
        const maBenhDung = [
            // T20-T32
            { type: 'range', from: 'T20', to: 'T32' },
            // X00-X19
            { type: 'range', from: 'X00', to: 'X19' },
            // W85-W87
            { type: 'range', from: 'W85', to: 'W87' },
        ];

        // Hàm kiểm tra mã bệnh có hợp lệ không
        function isMaBenhHopLe(ma) {
            if (!ma) return false;
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

        // Hàm kiểm tra XML5 DienBien_ls có chứa "chấn thương" hoặc "phù nề"
        function checkDienBienLS() {
            const dsXml5 = Array.isArray(patientData.Xml5) ? patientData.Xml5 : 
                          Array.isArray(patientData.xml5) ? patientData.xml5 : [];
            
            for (const xml5Item of dsXml5) {
                const dienBien = xml5Item?.DienBien_ls || 
                               xml5Item?.Dien_Bien_Ls || 
                               xml5Item?.dienBien_ls || 
                               xml5Item?.dien_bien_ls || 
                               '';
                
                if (typeof dienBien === 'string' && dienBien.trim()) {
                    const dienBienLower = dienBien.toLowerCase();
                    if (dienBienLower.includes('chấn thương') || 
                        dienBienLower.includes('chan thuong') ||
                        dienBienLower.includes('phù nề') || 
                        dienBienLower.includes('phu ne')) {
                        return true;
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
                    // Nếu không có mã bệnh hợp lệ, kiểm tra XML5 DienBien_ls
                    const coDienBienHopLe = checkDienBienLS();
                    
                    if (!coDienBienHopLe) {
                        result.isValid = false;
                        result.errors.push({ Id: thuoc.id || thuoc.Id, Error: 'Alphachymotrypsin (40.67) không có mã bệnh phù hợp theo quy định và không có thông tin chấn thương/phù nề trong diễn biến lâm sàng' });
                    }
                }
            }
        });

        if (!result.isValid && result.errors.length > 0) {
            result.message = result.errors.join('; ');
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push({Id: 0, Error: `Lỗi khi validate Thanh toán thuốc Alphachymotrypsin chỉ định sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT: ${error.message}`});
        result.message = 'Lỗi khi validate Thanh toán thuốc Alphachymotrypsin chỉ định sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT';
    }

    return result;
};

module.exports = validateRule_Id_28;