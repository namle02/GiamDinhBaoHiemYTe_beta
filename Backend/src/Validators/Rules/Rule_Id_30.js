/**
 * Rule 30: Kiểm tra thuốc mã 40.751 theo các điều kiện quy định
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_30 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán thuốc có hoạt chất Sylimarin (mã thuốc 40.751): thuốc Silygamma, Carsil 90mg, Fynkhepar chỉ định sử dụng không phù hợp với chỉ định trong tờ hướng dẫn sử dụng',
        ruleId: 'Rule_Id_30',
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
        
        // Kiểm tra xem bệnh nhân có thuốc mã 40.751 không
        const thuoc40751 = dsThuoc.filter(thuoc => 
            thuoc.Ma_Thuoc && String(thuoc.Ma_Thuoc).trim() === '40.751'
        );

        // Nếu không có thuốc 40.751 thì không cần kiểm tra
        if (thuoc40751.length === 0) {
            return result;
        }

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

        // Kiểm tra điều kiện 1: Mã bệnh B15->B19 hoặc K70->K77
        const regexMaBenh1 = [
            /^B1[5-9]$/i,  // B15->B19
            /^K7[0-7]$/i   // K70->K77
        ];

        const coMaBenhHopLe = dsMaBenh.some(ma => regexMaBenh1.some(regex => regex.test(ma)));
        if (coMaBenhHopLe) {
            // Đúng, không cần kiểm tra tiếp
            return result;
        }

        // Kiểm tra điều kiện 2: Dịch vụ trong XML4
        const xml4_data = Array.isArray(patientData.Xml4) ? patientData.Xml4 : [];
        const dsDichVuCheck = ['23.0019.1493', '23.0020.1493'];
        
        const dichVuHopLe = xml4_data.filter(item => {
            const maDichVu = item.Ma_Dich_Vu ? String(item.Ma_Dich_Vu).trim() : null;
            if (!dsDichVuCheck.includes(maDichVu)) {
                return false;
            }
            
            // So sánh Gia_Tri với mUC_BINH_THUONG
            const giaTri = item.Gia_Tri ? parseFloat(String(item.Gia_Tri).replace(/,/g, '')) : null;
            const mucBinhThuong = item.mUC_BINH_THUONG ? parseFloat(String(item.mUC_BINH_THUONG).replace(/,/g, '')) : null;
            
            if (giaTri !== null && mucBinhThuong !== null) {
                return giaTri > mucBinhThuong;
            }
            return false;
        });

        if (dichVuHopLe.length > 0) {
            // Đúng, không cần kiểm tra tiếp
            return result;
        }

        // Kiểm tra điều kiện 3: Thuốc nhóm 1 hoặc nhóm 2
        // Nhóm 1: 40.308, 40.312, 40.313, 40.256, 40.310, 40.155, 40.30.230, 40.221, 40.227, 40.242, 40.238, 40.293, 40.292, 40.288, 40.142, 40.131
        const nhom1 = ['40.308', '40.312', '40.313', '40.256', '40.310', '40.155', '40.30.230', '40.221', '40.227', '40.242', '40.238', '40.293', '40.292', '40.288', '40.142', '40.131'];
        
        // Nhóm 2: 40.48, 40.30.64, 40.30.61, 40.30, 40.37, 40.46
        const nhom2 = ['40.48', '40.30.64', '40.30.61', '40.30', '40.37', '40.46'];

        // Hàm lấy phần ngày từ Ngay_Yl (dạng yyyyMMddHHmm - 14 ký tự)
        // Trả về yyyyMMdd (8 ký tự đầu)
        function getNgayFromNgayYl(ngayYl) {
            if (!ngayYl) return null;
            const ngayStr = String(ngayYl).trim();
            // Lấy 8 ký tự đầu (yyyyMMdd)
            return ngayStr.length >= 8 ? ngayStr.substring(0, 8) : ngayStr;
        }

        // Hàm chuyển đổi yyyyMMdd sang Date object
        function parseDate(ngayStr) {
            if (!ngayStr || ngayStr.length < 8) return null;
            const year = parseInt(ngayStr.substring(0, 4), 10);
            const month = parseInt(ngayStr.substring(4, 6), 10) - 1; // Month is 0-indexed
            const day = parseInt(ngayStr.substring(6, 8), 10);
            return new Date(year, month, day);
        }

        // Hàm tính khoảng cách giữa 2 ngày (số ngày)
        function tinhKhoangCachNgay(ngay1, ngay2) {
            const date1 = parseDate(ngay1);
            const date2 = parseDate(ngay2);
            if (!date1 || !date2) return null;
            const diffTime = Math.abs(date2 - date1);
            return Math.floor(diffTime / (1000 * 60 * 60 * 24));
        }

        // Kiểm tra thuốc nhóm 1
        const thuocNhom1 = dsThuoc.filter(thuoc => {
            const maThuoc = thuoc.Ma_Thuoc ? String(thuoc.Ma_Thuoc).trim() : null;
            return nhom1.includes(maThuoc);
        });

        if (thuocNhom1.length > 0) {
            // Có thuốc nhóm 1, tiếp tục kiểm tra điều kiện 4
        } else {
            // Kiểm tra thuốc nhóm 2 với điều kiện cách 5 ngày
            const thuocNhom2 = dsThuoc.filter(thuoc => {
                const maThuoc = thuoc.Ma_Thuoc ? String(thuoc.Ma_Thuoc).trim() : null;
                return nhom2.includes(maThuoc);
            });

            if (thuocNhom2.length === 0) {
                // Không có thuốc nhóm 1 và nhóm 2 → SAI
                thuoc40751.forEach(thuoc => {
                    result.isValid = false;
                    result.errors.push({ 
                        Id: thuoc.id || thuoc.Id, 
                        Error: 'Thuốc 40.751 không đáp ứng điều kiện: không có mã bệnh B15-B19/K70-K77, không có dịch vụ 23.0019.1493/23.0020.1493 với GiaTri > mucbinhthuong, và không có thuốc nhóm 1 hoặc nhóm 2 hợp lệ' 
                    });
                });
                return result;
            }

            // Kiểm tra khoảng cách 5 ngày giữa thuốc 40.751 và thuốc nhóm 2
            let coThuocNhom2HopLe = false;
            for (const thuoc751 of thuoc40751) {
                const ngayYl751 = getNgayFromNgayYl(thuoc751.Ngay_Yl);
                if (!ngayYl751) continue;

                for (const thuocN2 of thuocNhom2) {
                    const ngayYlN2 = getNgayFromNgayYl(thuocN2.Ngay_Yl);
                    if (!ngayYlN2) continue;

                    const khoangCach = tinhKhoangCachNgay(ngayYl751, ngayYlN2);
                    if (khoangCach !== null && khoangCach >= 5) {
                        coThuocNhom2HopLe = true;
                        break;
                    }
                }
                if (coThuocNhom2HopLe) break;
            }

            if (!coThuocNhom2HopLe) {
                // Không đáp ứng điều kiện nhóm 2 (cách 5 ngày) → SAI
                thuoc40751.forEach(thuoc => {
                    result.isValid = false;
                    result.errors.push({ 
                        Id: thuoc.id || thuoc.Id, 
                        Error: 'Thuốc 40.751 không đáp ứng điều kiện: thuốc nhóm 2 phải cách ngày y lệnh của thuốc 40.751 ít nhất 5 ngày' 
                    });
                });
                return result;
            }
        }

        // Kiểm tra điều kiện 4: Dịch vụ 18.0015.0001 trong XML3
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        const dichVu180015 = xml3_data.filter(item => {
            const maDichVu = item.Ma_Dich_Vu ? String(item.Ma_Dich_Vu).trim() : null;
            return maDichVu === '18.0015.0001';
        });

        if (dichVu180015.length === 0) {
            // Không có dịch vụ 18.0015.0001 → SAI
            thuoc40751.forEach(thuoc => {
                result.isValid = false;
                result.errors.push({ 
                    Id: thuoc.id || thuoc.Id, 
                    Error: 'Thuốc 40.751 không đáp ứng điều kiện: không có dịch vụ 18.0015.0001 trong XML3' 
                });
            });
            return result;
        }

        // Kiểm tra ket_luan có chứa "gan nhiễm mỡ", "xơ gan", hoặc "gan thô"
        const ketLuanHopLe = dichVu180015.some(item => {
            const ketLuan = item.ket_luan || item.ketluan || '';
            const ketLuanLower = String(ketLuan).toLowerCase();
            return ketLuanLower.includes('gan nhiễm mỡ') || 
                   ketLuanLower.includes('xơ gan') || 
                   ketLuanLower.includes('gan thô');
        });

        if (!ketLuanHopLe) {
            // Không có ket_luan hợp lệ → SAI
            thuoc40751.forEach(thuoc => {
                result.isValid = false;
                result.errors.push({ 
                    Id: thuoc.id || thuoc.Id, 
                    Error: 'Thuốc 40.751 không đáp ứng điều kiện: dịch vụ 18.0015.0001 không có ket_luan chứa "gan nhiễm mỡ", "xơ gan", hoặc "gan thô"' 
                });
            });
            return result;
        }

        // Tất cả điều kiện đều đáp ứng → ĐÚNG
        return result;

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Rule 30: ${error.message}`);
        result.message = 'Lỗi khi validate Rule 30';
    }

    return result;
};

module.exports = validateRule_Id_30;
