/**
 * Rule 44: Chặn thanh toán BHYT đối với các dịch vụ thở máy khi (số lượng * 24) < (NGAY_KQ - NGAY_TH_YL)
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const ds_dichvu = [
    "01.0129.0209",
    "01.0128.0209",
    "01.0131.0209",
    "01.0130.0209",
    "01.0142.0209",
    "01.0144.0209",
    "01.0132.0209",
    "01.0135.0209",
    "01.0139.0209",
    "01.0138.0209",
    "01.0141.0209",
    "01.0140.0209",
    "01.0134.0209",
    "01.0137.0209",
    "01.0136.0209",
    "01.0133.0209",
    "01.0153.0297",
    "03.0058.0209",
    "03.0082.0209",
    "03.0054.0297"
];

function parseDateTime(dateTimeStr) {
    // Hỗ trợ các format:
    // - "YYYY-MM-DD HH:mm:ss" hoặc "YYYY-MM-DDTHH:mm:ss"
    // - "YYYY-MM-DD"
    // - "YYYYMMDDHHmm" hoặc "YYYYMMDDHHmmss"
    if (!dateTimeStr) return null;
    const raw = String(dateTimeStr).trim();
    if (!raw) return null;

    // Format digits: YYYYMMDDHHmm[ss]
    if (/^\d{12}(\d{2})?$/.test(raw)) {
        const year = Number(raw.slice(0, 4));
        const month = Number(raw.slice(4, 6)) - 1;
        const day = Number(raw.slice(6, 8));
        const hour = Number(raw.slice(8, 10));
        const min = Number(raw.slice(10, 12));
        const sec = raw.length >= 14 ? Number(raw.slice(12, 14)) : 0;
        return new Date(year, month, day, hour, min, sec, 0);
    }

    // Format hyphen: YYYY-MM-DD[ HH:mm:ss] or YYYY-MM-DDTHH:mm:ss
    const cleanStr = raw.replace('T', ' ');
    const dateParts = cleanStr.split(' ');
    let [year, month, day] = [0, 0, 0];
    let [hour, min, sec] = [0, 0, 0];
    if (dateParts[0]) {
        [year, month, day] = dateParts[0].split('-').map(Number);
    }
    if (dateParts[1]) {
        const timeParts = dateParts[1].split(':').map(Number);
        [hour, min, sec] = [timeParts[0], timeParts[1] || 0, timeParts[2] || 0];
    }
    if (year && month && day) return new Date(year, month - 1, day, hour, min, sec);
    return null;
}

const validateRule_Id_44 = async (patientData) => {
    const result = {
        ruleName: 'Chặn thanh toán BHYT đối với các dịch vụ thở máy chưa đúng quy định ',
        ruleId: 'Rule_Id_44',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile: 'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;

        if (!xml3_data || !Array.isArray(xml3_data)) {
            throw new Error('Dữ liệu XML3 không hợp lệ hoặc thiếu');
        }
        
        const dsDichVu = xml3_data.filter(item => ds_dichvu.includes(item.Ma_Dich_Vu));

        dsDichVu.forEach((item, idx) => {
            // Lấy ra ngày thực hiện y lệnh và ngày kết quả (dạng string)
            const ngayThYlStr = item.Ngay_Th_Yl ?? item.Ngay_th_yl;
            const ngayKqStr = item.Ngay_Kq ?? item.Ngay_kq;

            // parse sang Date
            const ngayThYl = parseDateTime(ngayThYlStr);
            const ngayKq = parseDateTime(ngayKqStr);

            // Nếu parse lỗi hoặc thiếu ngày thì bỏ qua kiểm tra
            if (!ngayThYl || !ngayKq) {
                return;
            }

            // Tính số giờ chênh lệch (NGAY_KQ - NGAY_TH_YL)
            const diffMs = ngayKq - ngayThYl;
            if (diffMs < 0) {
                // Data không hợp lệ (ngày KQ trước ngày TH), bỏ qua
                return;
            }
            const diffHours = Math.ceil(diffMs / (1000 * 60 * 60)); // Chuyển từ milliseconds sang số giờ

            // item.So_Luong có thể dạng số hoặc Decimal128, nên ép sang số nếu cần
            let soLuong = item.So_Luong;
            
            if (soLuong && typeof soLuong === 'object' && typeof soLuong.toString === "function") {
                const soLuongString = soLuong.toString();
                soLuong = Number(soLuongString);
            } else {
                soLuong = Number(soLuong);
            }

            // Theo nghiệp vụ: So_Luong là số ngày -> đổi sang giờ
            const soLuongHours = soLuong * 24;

            // Nếu (số lượng * 24) >= số giờ chênh lệch thì ĐÚNG; ngược lại thì SAI và báo lỗi
            if (soLuongHours >= diffHours) {
            } else {
                result.isValid = false;
                result.errors.push({
                    Id: item.id || item.Id,
                    Error: `Chặn thanh toán BHYT: Số lượng quy đổi (${soLuongHours} giờ = ${soLuong}*24) không đạt điều kiện >= số giờ chênh lệch (${diffHours} giờ) giữa ngày kết quả và ngày thực hiện y lệnh`
                });
            }
        });

    }
    catch (error) {
        result.isValid = false;
        result.errors.push(
            `Lỗi khi validate Chặn thanh toán BHYT đối với các dịch vụ thở máy: ${error.message}`
        );
        result.message =
            "Lỗi khi validate Chặn thanh toán BHYT đối với các dịch vụ thở máy";
    }
    return result;
}

module.exports = validateRule_Id_44;