/**
 * Rule 7: Thanh toán dịch vụ PHCN trong điều trị thoái hóa cột sống cổ/cột sống thắt lưng: Hồng ngoại, đắp paraphin, ...không đúng hướng dẫn tại Quyết định số 3109/QĐ-BYT chẩn đoán, điều trị chuyên ngành PHCN
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
        // Lấy thông tin bệnh nhân từ Xml1
        const xml1_data = Array.isArray(patientData.Xml1) && patientData.Xml1.length > 0 ? patientData.Xml1[0] : {};
        
        // Danh sách mã dịch vụ PHCN cần kiểm tra (phải có Ngay_YL khác nhau)
        const danhsachdichvu = [
            '17.0011.0237',  // Điều trị bằng tia hồng ngoại
            '17.0018.0221',  // Điều trị bằng Parafin
            '17.0004.0232',  // Điều trị bằng từ trường
            '17.0023.0272'   // Điều trị bằng bùn
        ];

        // Hàm kiểm tra mã bệnh là M47 hoặc M54.5
        function isMaBenhHopLe(ma) {
            if (!ma) return false;
            ma = ma.toUpperCase().replace(/\s/g, '');
            // Kiểm tra M47 (có thể có hoặc không có phần mở rộng)
            if (/^M47(\.\d+)?$/i.test(ma)) return true;
            // Kiểm tra M54.5 (chính xác)
            if (ma === 'M54.5' || ma === 'M545') return true;
            return false;
        }

        // Thu thập tất cả mã bệnh từ XML1 (Ma_Benh và Ma_Benh_Yhct)
        let dsMaBenh = [];
        
        // Lấy từ XML1 - Ma_Benh_Chinh (nếu có)
        if (xml1_data.Ma_Benh_Chinh) {
            dsMaBenh.push(String(xml1_data.Ma_Benh_Chinh).trim().toUpperCase());
        }
        
        // Lấy từ XML1 - Ma_Benh_Kt (nếu có)
        if (xml1_data.Ma_Benh_Kt) {
            if (typeof xml1_data.Ma_Benh_Kt === 'string') {
                dsMaBenh = dsMaBenh.concat(xml1_data.Ma_Benh_Kt.split(';').map(s => s.trim().toUpperCase()).filter(Boolean));
            } else if (Array.isArray(xml1_data.Ma_Benh_Kt)) {
                dsMaBenh = dsMaBenh.concat(
                    xml1_data.Ma_Benh_Kt.flatMap(mb => (typeof mb === 'string' ? mb.split(';').map(s => s.trim().toUpperCase()) : [])).filter(Boolean)
                );
            }
        }
        
        // Lấy từ XML1 - Ma_Benh_Yhct (nếu có)
        if (xml1_data.Ma_Benh_Yhct) {
            if (typeof xml1_data.Ma_Benh_Yhct === 'string') {
                dsMaBenh = dsMaBenh.concat(xml1_data.Ma_Benh_Yhct.split(';').map(s => s.trim().toUpperCase()).filter(Boolean));
            } else if (Array.isArray(xml1_data.Ma_Benh_Yhct)) {
                dsMaBenh = dsMaBenh.concat(
                    xml1_data.Ma_Benh_Yhct.flatMap(mb => (typeof mb === 'string' ? mb.split(';').map(s => s.trim().toUpperCase()) : [])).filter(Boolean)
                );
            }
        }

        // Lấy từ XML3 - Ma_Benh và Ma_Benh_Yhct
        xml3_data.forEach(item => {
            if (item.Ma_Benh) {
                dsMaBenh.push(String(item.Ma_Benh).trim().toUpperCase());
            }
            if (item.Ma_Benh_Yhct) {
                dsMaBenh.push(String(item.Ma_Benh_Yhct).trim().toUpperCase());
            }
        });

        dsMaBenh = Array.from(new Set(dsMaBenh)); // loại trùng

        // Kiểm tra xem bệnh nhân có mã bệnh M47 hoặc M54.5 không
        const coMaBenhHopLe = dsMaBenh.some(isMaBenhHopLe);

        if (coMaBenhHopLe) {
            // Lọc các dịch vụ cần kiểm tra (chỉ lấy các dịch vụ trong danh sách và có Ngay_YL)
            const dichVuCanKiemTra = xml3_data.filter(item => 
                danhsachdichvu.includes(item.Ma_Dich_Vu) && item.Ngay_Yl
            );

            // Nhóm các dịch vụ theo Ngay_YL
            const nhomTheoNgayYL = {};
            dichVuCanKiemTra.forEach(item => {
                const ngayYL = String(item.Ngay_Yl).trim();
                if (!nhomTheoNgayYL[ngayYL]) {
                    nhomTheoNgayYL[ngayYL] = [];
                }
                nhomTheoNgayYL[ngayYL].push(item);
            });

            // Kiểm tra xem có ngày nào có nhiều hơn 1 dịch vụ không (tức là có cặp trùng)
            Object.keys(nhomTheoNgayYL).forEach(ngayYL => {
                const dsDichVu = nhomTheoNgayYL[ngayYL];
                if (dsDichVu.length > 1) {
                    // Tìm tất cả các cặp dịch vụ có cùng Ngay_YL
                    for (let i = 0; i < dsDichVu.length; i++) {
                        for (let j = i + 1; j < dsDichVu.length; j++) {
                            result.isValid = false;
                            result.errors.push({
                                Id: dsDichVu[i].Id || dsDichVu[j].Id,
                                Error: `Bệnh nhân có mã bệnh M47 hoặc M54.5, các dịch vụ ${dsDichVu[i].Ma_Dich_Vu} và ${dsDichVu[j].Ma_Dich_Vu} có cùng Ngay_YL: ${ngayYL}`
                            });
                        }
                    }
                }
            });
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ PHCN trong điều trị thoái hóa cột sống cổ/cột sống thắt lưng: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ PHCN trong điều trị thoái hóa cột sống cổ/cột sống thắt lưng';
    }

    return result;
};

module.exports = validateRule_Id_7;