/**
 * Rule 11: Xét nghiệm "Định lượng Pro-calcitonin [Máu]" chỉ định không đúng khoảng cách hoặc xét nghiệm "Định lượng CRP/CRPhs" thanh toán đồng thời với "Định lượng Pro-calcitonin [Máu]" không đúng quy định tại Thông tư số 50/2017/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_11 = async (patientData) => {
    const result = {
        ruleName: 'Xét nghiệm "Định lượng Pro-calcitonin [Máu]" chỉ định không đúng khoảng cách ',
        ruleId: 'Rule_Id_11',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    /**
     * Parse date string in format "YYYYMMDDHHmm" (e.g., 202501181224) to Date
     */
    function parseCustomDate(str) {
        if (!str || typeof str !== "string" || str.length < 8) return null;
        const year = Number(str.substr(0, 4));
        const month = Number(str.substr(4, 2)) - 1;
        const day = Number(str.substr(6, 2));
        const hour = str.length >= 10 ? Number(str.substr(8, 2)) : 0;
        const min = str.length >= 12 ? Number(str.substr(10, 2)) : 0;
        return new Date(year, month, day, hour, min, 0, 0);
    }

    function getId(item) {
        return item?.Id ?? item?.id ?? item?.ID ?? 'N/A';
    }

    function getKetQua(xml4Item) {
        return xml4Item?.Gia_Tri ?? xml4Item?.gia_Tri ?? xml4Item?.ketQua ?? xml4Item?.KetQua ?? null;
    }

    function getMucBinhThuong(xml4Item) {
        return xml4Item?.mUC_BINH_THUONG ?? xml4Item?.MucBinhThuong ?? xml4Item?.mucBinhThuong ?? null;
    }

    /**
     * Parse số từ string có thể chứa ký tự so sánh (≤, ≥, <, >, <=, >=)
     * Ví dụ: "≤ 0.046" → 0.046, ">= 0.5" → 0.5, "< 1.0" → 1.0
     */
    function parseNumberWithComparison(str) {
        if (!str || typeof str !== 'string') return null;
        
        // Loại bỏ các ký tự so sánh: ≤, ≥, <, >, <=, >=
        let cleaned = str.trim()
            .replace(/^[≤≥<>]=?\s*/i, '') // Loại bỏ ≤, ≥, <, >, <=, >= ở đầu
            .replace(/^\s*[≤≥<>]=?/i, '') // Loại bỏ nếu có khoảng trắng trước
            .trim();
        
        // Tìm số (có thể có dấu chấm thập phân, dấu âm)
        const match = cleaned.match(/-?\d+\.?\d*/);
        if (match) {
            const num = parseFloat(match[0]);
            return isNaN(num) ? null : num;
        }
        
        return null;
    }

    try {
        
        // Bước 1: Lấy tất cả mã bệnh của bệnh nhân
        const xml1_data = Array.isArray(patientData.Xml1) && patientData.Xml1.length > 0 ? patientData.Xml1[0] : {};
        const xml3_data = patientData.Xml3 || [];
        const xml4_data = patientData.Xml4 || [];
        
        if (!Array.isArray(xml3_data)) {
            throw new Error('Dữ liệu XML3 không hợp lệ hoặc thiếu');
        }
        
        if (!Array.isArray(xml4_data)) {
            throw new Error('Dữ liệu XML4 không hợp lệ hoặc thiếu');
        }

        // Thu thập tất cả mã bệnh từ XML1 và XML3
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
        
        // Kiểm tra xem bệnh nhân có mã bệnh R57.2 không
        const hasR57_2 = dsMaBenh.some(ma => ma === 'R57.2' || ma === 'R572');
        const minDistance = hasR57_2 ? 24 : 48;

        // Bước 2: Lọc các dịch vụ có Ma_Dich_Vu = 23.0130.1549 và có ketQua, mucBinhThuong từ XML4, thời gian từ XML3
        // Tạo map XML4 theo Ma_Dich_Vu để join với XML3
        const xml4ByMaDichVu = {};
        xml4_data.forEach(xml4Item => {
            const maDV = xml4Item.Ma_Dich_Vu;
            if (maDV) {
                if (!xml4ByMaDichVu[maDV]) {
                    xml4ByMaDichVu[maDV] = [];
                }
                xml4ByMaDichVu[maDV].push(xml4Item);
            }
        });
        
        const dichVuList = xml3_data
            .filter(item => item.Ma_Dich_Vu === '23.0130.1549')
            .map(item => {
                // Tìm XML4 tương ứng với dịch vụ này
                const xml4Items = xml4ByMaDichVu[item.Ma_Dich_Vu] || [];
                // Lấy XML4 item đầu tiên có ketQua và mucBinhThuong
                const xml4Item = xml4Items.find(x4 => {
                    const ketQua = getKetQua(x4);
                    const mucBinhThuong = getMucBinhThuong(x4);
                    return ketQua != null && mucBinhThuong != null;
                });
                
                if (!xml4Item) return null;
                
                const ngayThYl = item.Ngay_Th_Yl ?? item.Ngay_th_yl;
                const ngayKq = item.Ngay_Kq ?? item.Ngay_kq;
                const hasTime = (ngayThYl != null && ngayKq != null) || item.Ngay_Yl != null;
                
                if (!hasTime) return null;
                
                return { ...item, __xml4Item: xml4Item };
            })
            .filter(item => item != null);

        // Kiểm tra điều kiện 1: ketQua > mucBinhThuong*2
        for (const item of dichVuList) {
            const xml4Item = item.__xml4Item;
            const ketQuaRaw = getKetQua(xml4Item);
            const mucBinhThuongRaw = getMucBinhThuong(xml4Item);
            const ketQua = parseFloat(ketQuaRaw);
            // Parse mucBinhThuong có thể chứa ký tự so sánh như "≤ 0.046"
            const mucBinhThuong = parseNumberWithComparison(mucBinhThuongRaw) ?? parseFloat(mucBinhThuongRaw);

            if (isNaN(ketQua) || isNaN(mucBinhThuong)) {
                result.isValid = false;
                result.errors.push({
                    Id: getId(item),
                    errorType: 'INVALID_RESULT_VALUE',
                    Error: `Dịch vụ có Ma_Dich_Vu = 23.0130.1549 có ketQua hoặc mucBinhThuong không hợp lệ. ketQua: ${ketQuaRaw}, mucBinhThuong: ${mucBinhThuongRaw}`
                });
                continue;
            }

            const mucBinhThuongX2 = mucBinhThuong * 2;

            // Nếu ketQua <= mucBinhThuong*2 thì sai
            if (ketQua <= mucBinhThuongX2) {
                result.isValid = false;
                result.errors.push({
                    Id: getId(item),
                    errorType: 'INVALID_RESULT_VALUE',
                    Error: `Dịch vụ có Ma_Dich_Vu = 23.0130.1549 không thỏa mãn điều kiện: ketQua (${ketQua}) phải > mucBinhThuong*2 (${mucBinhThuongX2})`
                });
            }
        }

        // Kiểm tra điều kiện 2: Khoảng cách giữa các lần xét nghiệm (Ngay_th_yl / Ngay_kq), fallback dùng Ngay_Yl
        // Chuẩn hoá dữ liệu thời gian cho từng dịch vụ
        const dichVuNormalized = dichVuList
            .map(item => {
                const ngayThYl = item.Ngay_Th_Yl ?? item.Ngay_th_yl;
                const ngayKq = item.Ngay_Kq ?? item.Ngay_kq;
                const startAt = parseCustomDate(ngayThYl ?? item.Ngay_Yl);
                const endAt = parseCustomDate(ngayKq ?? item.Ngay_Yl);
                const safeEndAt = startAt && endAt && endAt < startAt ? startAt : endAt;
                return { ...item, __startAt: startAt, __endAt: safeEndAt };
            })
            .filter(item => item.__startAt && item.__endAt);

        // Sắp xếp theo thời điểm thực hiện (Ngay_th_yl, fallback Ngay_Yl)
        const dichVuSorted = dichVuNormalized.sort((a, b) => a.__startAt - b.__startAt);
        
        // Kiểm tra khoảng cách giữa các cặp dịch vụ liên tiếp:
        // diffHours = (Ngay_th_yl của lần sau) - (Ngay_kq của lần trước)
        for (let i = 0; i < dichVuSorted.length - 1; i++) {
            const item1 = dichVuSorted[i];
            const item2 = dichVuSorted[i + 1];

            const start2 = item2.__startAt;
            const end1 = item1.__endAt;

            if (!end1 || !start2) {
                continue;
            }

            // Tính khoảng cách (giờ) giữa thời điểm trả KQ của DV trước và thời điểm thực hiện DV sau
            const diffMs = start2 - end1;
            const diffHours = diffMs / (1000 * 60 * 60);

            if (diffHours < minDistance) {
                result.isValid = false;
                const maBenhInfo = hasR57_2 ? 'có mã bệnh R57.2' : 'không có mã bệnh R57.2';
                result.errors.push({
                    Id: getId(item2),
                    errorType: 'INVALID_TIME_INTERVAL',
                    Error: `Dịch vụ có Ma_Dich_Vu = 23.0130.1549 có khoảng cách ${diffHours.toFixed(2)} giờ nhỏ hơn yêu cầu ${minDistance} giờ (${maBenhInfo}). Dịch vụ trước: ID ${getId(item1)} (Ngay_Kq: ${(item1.Ngay_Kq ?? item1.Ngay_kq ?? item1.Ngay_Yl) || 'N/A'}), Dịch vụ sau: ID ${getId(item2)} (Ngay_Th_Yl: ${(item2.Ngay_Th_Yl ?? item2.Ngay_th_yl ?? item2.Ngay_Yl) || 'N/A'})`
                });
            }
        }

        // Cập nhật ruleName và message dựa trên loại lỗi
        if (result.errors.length > 0) {
            const loiKhoangCach = result.errors.filter(e => e.errorType === 'INVALID_TIME_INTERVAL');
            const loiKetQua = result.errors.filter(e => e.errorType === 'INVALID_RESULT_VALUE');
            
            // Cập nhật ruleName dựa trên loại lỗi
            if (loiKhoangCach.length > 0 && loiKetQua.length > 0) {
                // Có cả 2 loại lỗi
                result.ruleName = 'Xét nghiệm "Định lượng Pro-calcitonin [Máu]" chỉ định không đúng khoảng cách thời gian và có kết quả không hợp lệ';
                result.message = `Có ${loiKhoangCach.length} dịch vụ chỉ định không đúng khoảng cách thời gian và ${loiKetQua.length} dịch vụ có kết quả không hợp lệ.`;
            } else if (loiKhoangCach.length > 0) {
                // Chỉ có lỗi khoảng cách
                result.ruleName = 'Xét nghiệm "Định lượng Pro-calcitonin [Máu]" chỉ định không đúng khoảng cách thời gian';
                result.message = `Có ${loiKhoangCach.length} dịch vụ chỉ định không đúng khoảng cách thời gian.`;
            } else if (loiKetQua.length > 0) {
                // Chỉ có lỗi kết quả
                result.ruleName = 'Xét nghiệm "Định lượng Pro-calcitonin [Máu]" có kết quả không hợp lệ';
                result.message = `Có ${loiKetQua.length} dịch vụ có kết quả không hợp lệ.`;
            } else {
                // Lỗi khác (dữ liệu không hợp lệ)
                result.ruleName = 'Xét nghiệm "Định lượng Pro-calcitonin [Máu]" có dữ liệu không hợp lệ';
                result.message = 'Có dịch vụ có dữ liệu không hợp lệ.';
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push({
            Id: 'N/A',
            errorType: 'SYSTEM_ERROR',
            Error: `Lỗi khi kiểm tra logic dịch vụ Pro-calcitonin: ${error.message}`
        });
        result.message = 'Lỗi khi validate dịch vụ Pro-calcitonin';
        result.ruleName = 'Xét nghiệm "Định lượng Pro-calcitonin [Máu]" - Lỗi hệ thống';
    }

    return result;
};

module.exports = validateRule_Id_11;