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

    function getKetQua(item) {
        return item?.ketQua ?? item?.KetQua ?? null;
    }

    function getMucBinhThuong(item) {
        return item?.mucBinhThuong ?? item?.MucBinhThuong ?? null;
    }

    try {
        
        // Bước 1: Lấy tất cả mã bệnh của bệnh nhân
        const xml1_data = Array.isArray(patientData.Xml1) && patientData.Xml1.length > 0 ? patientData.Xml1[0] : {};
        const xml3_data = patientData.Xml3 || [];
        
        if (!Array.isArray(xml3_data)) {
            throw new Error('Dữ liệu XML3 không hợp lệ hoặc thiếu');
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

        // Bước 2: Lọc các dịch vụ có Ma_Dich_Vu = 23.0130.1549 và có ketQua, mucBinhThuong, thời gian
        const dichVuList = xml3_data.filter(item => {
            const ngayThYl = item.Ngay_Th_Yl ?? item.Ngay_th_yl;
            const ngayKq = item.Ngay_Kq ?? item.Ngay_kq;
            const hasTime = (ngayThYl != null && ngayKq != null) || item.Ngay_Yl != null;
            const ketQua = getKetQua(item);
            const mucBinhThuong = getMucBinhThuong(item);
            return item.Ma_Dich_Vu === '23.0130.1549' && 
                   ketQua != null && 
                   mucBinhThuong != null &&
                   hasTime;
        });

        // Kiểm tra điều kiện 1: ketQua > mucBinhThuong*2
        let index = 0;
        for (const item of dichVuList) {
            index++;
            
            const ketQua = parseFloat(getKetQua(item));
            const mucBinhThuong = parseFloat(getMucBinhThuong(item));

            if (isNaN(ketQua) || isNaN(mucBinhThuong)) {
                result.isValid = false;
                result.errors.push({
                    Id: getId(item),
                    Error: `Dịch vụ có Ma_Dich_Vu = 23.0130.1549 có ketQua hoặc mucBinhThuong không hợp lệ. ketQua: ${getKetQua(item)}, mucBinhThuong: ${getMucBinhThuong(item)}`
                });
                continue;
            }

            const mucBinhThuongX2 = mucBinhThuong * 2;

            // Nếu ketQua <= mucBinhThuong*2 thì sai
            if (ketQua <= mucBinhThuongX2) {
                result.isValid = false;
                result.errors.push({
                    Id: getId(item),
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
                    Error: `Dịch vụ có Ma_Dich_Vu = 23.0130.1549 có khoảng cách ${diffHours.toFixed(2)} giờ nhỏ hơn yêu cầu ${minDistance} giờ (${maBenhInfo}). Dịch vụ trước: ID ${getId(item1)} (Ngay_Kq: ${(item1.Ngay_Kq ?? item1.Ngay_kq ?? item1.Ngay_Yl) || 'N/A'}), Dịch vụ sau: ID ${getId(item2)} (Ngay_Th_Yl: ${(item2.Ngay_Th_Yl ?? item2.Ngay_th_yl ?? item2.Ngay_Yl) || 'N/A'})`
                });
            }
        }

        if (result.errors.length > 0) {
            result.message = 'Có dịch vụ "Định lượng Pro-calcitonin [Máu]" không thỏa mãn điều kiện ketQua > mucBinhThuong*2 hoặc khoảng cách giữa các lần chỉ định không đúng quy định.';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi kiểm tra logic dịch vụ Pro-calcitonin: ${error.message}`);
        result.message = 'Lỗi khi validate dịch vụ Pro-calcitonin';
    }

    return result;
};

module.exports = validateRule_Id_11;