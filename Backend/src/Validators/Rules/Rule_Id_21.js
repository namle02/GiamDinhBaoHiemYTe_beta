/**
 * Rule 21: Thanh toán số ngày giường điều trị nội trú không đúng quy định tại điểm a và điểm b khoản 1 Điều 6 Thông tư số 22/2023/TT-BYT.
 * - Lấy tất cả dịch vụ Ma_Nhom = 15, tính số ngày giường từng dịch vụ (Ngay_kq - Ngay_yl: <4h=0, 4h~<24h=1, >=24h=ceil(h/24)).
 * - So sánh tổng số ngày giường với (ngày ra - ngày vào) từ XML1; nếu Ket_Qua_Dtri 4 hoặc 5 thì +1.
 * - Trong 1 ngày (theo Ngay_yl) tổng số ngày giường không được > 1.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const { getEffectiveNgayRa } = require('../utils/ngayRaHelper');

function parseDate(str) {
    if (str == null || typeof str !== 'string') return null;
    const s = String(str).trim();
    if (s.length < 8) return null;
    const y = Number(s.substring(0, 4));
    const m = Number(s.substring(4, 6)) - 1;
    const d = Number(s.substring(6, 8));
    const h = s.length >= 10 ? Number(s.substring(8, 10)) || 0 : 0;
    const min = s.length >= 12 ? Number(s.substring(10, 12)) || 0 : 0;
    return new Date(y, m, d, h, min, 0, 0);
}

/** Chỉ lấy phần ngày (00:00:00) để tính chênh lệch theo ngày */
function toDateOnly(d) {
    if (!d || !(d instanceof Date)) return null;
    return new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0);
}

/** Chuẩn hóa một entry lỗi đúng format cho WPF: { id: number | null, error: string } */
function formatError(id, message) {
    const numId = id == null ? null : (typeof id === 'number' && Number.isInteger(id) ? id : (typeof id === 'string' && /^\d+$/.test(id) ? parseInt(id, 10) : null));
    return { id: numId, error: message || '' };
}

const validateRule_Id_21 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán số ngày giường điều trị nội trú không đúng quy định tại điểm a và điểm b khoản 1 Điều 6 Thông tư số 22/2023/TT-BYT.',
        ruleId: 'Rule_Id_21',
        isValid: true,
        validateField: 'Ngay_yl',
        validateFile: 'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        console.log('[Rule_Id_21] Bắt đầu kiểm tra.');
        const xml1 = patientData.Xml1 && patientData.Xml1[0] ? patientData.Xml1[0] : {};
        const xml3 = patientData.Xml3 || [];

        const dichVuNhom15 = xml3.filter(item => item.Ma_Nhom == '15');
        console.log('[Rule_Id_21] Số dịch vụ Ma_Nhom=15:', dichVuNhom15.length, '| Tổng dịch vụ Xml3:', xml3.length);
        if (dichVuNhom15.length === 0) {
            console.log('[Rule_Id_21] Không có dịch vụ nhóm 15 -> bỏ qua, isValid=true');
            return result;
        }

        // --- Tính số ngày giường cho từng dịch vụ ---
        const MS_PER_HOUR = 1000 * 60 * 60;
        const listWithSoNgay = [];

        for (const dv of dichVuNhom15) {
            const ngayThYlStr = dv.Ngay_yl ?? dv.Ngay_Yl ?? '';
            const ngayKqStr = dv.Ngay_Kq ?? dv.Ngay_kq ?? '';
            const start = parseDate(ngayThYlStr);
            const end = parseDate(ngayKqStr);

            let soNgayGiuongDv = 0;
            let dateKey = ''; // yyyyMMdd của Ngay_yl

            if (start && end) {
                const diffMs = end.getTime() - start.getTime();
                const diffHours = diffMs / MS_PER_HOUR;

                if (diffHours < 4) {
                    soNgayGiuongDv = 0;
                } else if (diffHours < 24) {
                    soNgayGiuongDv = 1;
                } else {
                    soNgayGiuongDv = Math.ceil(diffHours / 24);
                }

                const y = start.getFullYear();
                const m = String(start.getMonth() + 1).padStart(2, '0');
                const day = String(start.getDate()).padStart(2, '0');
                dateKey = `${y}${m}${day}`;
            }

            console.log('[Rule_Id_21] DV Id:', dv.id || dv.Id, '| Ngay_yl:', ngayThYlStr, '| Ngay_Kq:', ngayKqStr, '| diffHours:', start && end ? ((end.getTime() - start.getTime()) / MS_PER_HOUR).toFixed(2) : 'N/A', '| soNgayGiuong:', soNgayGiuongDv, '| dateKey:', dateKey || '(trống)');

            listWithSoNgay.push({
                item: dv,
                soNgayGiuong: soNgayGiuongDv,
                dateKey
            });
        }

        const totalSoNgayGiuong = listWithSoNgay.reduce((s, x) => s + x.soNgayGiuong, 0);
        console.log('[Rule_Id_21] listWithSoNgay:', JSON.stringify(listWithSoNgay.map(x => ({ id: x.item?.id ?? x.item?.Id, soNgayGiuong: x.soNgayGiuong, dateKey: x.dateKey }))));
        console.log('[Rule_Id_21] Tổng số ngày giường (từ dịch vụ):', totalSoNgayGiuong);

        // --- Kỳ vọng từ XML1: ngày ra - ngày vào (chỉ theo ngày), Ket_Qua_Dtri 4 hoặc 5 thì +1 ---
        const ngayRaStr = getEffectiveNgayRa(xml1);
        const ngayVaoStr = xml1.Ngay_Vao ?? xml1.Ngay_vao ?? '';

        const ngayRa = toDateOnly(parseDate(ngayRaStr));
        const ngayVao = toDateOnly(parseDate(ngayVaoStr));

        let expectedSoNgayGiuong = 0;
        if (ngayRa && ngayVao) {
            const diffMs = ngayRa.getTime() - ngayVao.getTime();
            const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));
            const ketQuaDtri = xml1.Ket_Qua_Dtri ?? xml1.ket_qua_Dtri;
            const is4or5 = Number(ketQuaDtri) === 4 || Number(ketQuaDtri) === 5;
            expectedSoNgayGiuong = is4or5 ? diffDays + 1 : diffDays;
            console.log('[Rule_Id_21] XML1 Ngay_Vao:', ngayVaoStr, '| Ngay_Ra(effective):', ngayRaStr, '| diffDays:', diffDays, '| Ket_Qua_Dtri:', ketQuaDtri, '| is4or5:', is4or5, '| Kỳ vọng số ngày giường:', expectedSoNgayGiuong);
        } else {
            console.log('[Rule_Id_21] XML1 thiếu Ngay_Vao hoặc Ngay_Ra -> expectedSoNgayGiuong = 0');
        }

        // --- Kiểm tra 1: tổng số ngày giường phải bằng kỳ vọng ---
        if (expectedSoNgayGiuong !== totalSoNgayGiuong) {
            console.log('[Rule_Id_21] Kiểm tra 1 FAIL: tổng ngày giường(', totalSoNgayGiuong, ') != kỳ vọng(', expectedSoNgayGiuong, ')');
            result.isValid = false;
            const msg = `Số ngày giường theo dịch vụ (${totalSoNgayGiuong}) không bằng số ngày theo hồ sơ (ngày ra - ngày vào${Number(xml1.Ket_Qua_Dtri) === 4 || Number(xml1.Ket_Qua_Dtri) === 5 ? ' + 1' : ''}) = ${expectedSoNgayGiuong}`;
            dichVuNhom15.forEach(item => {
                result.errors.push(formatError(item.id || item.Id, msg));
            });
        } else {
            console.log('[Rule_Id_21] Kiểm tra 1 PASS: tổng ngày giường = kỳ vọng =', expectedSoNgayGiuong);
        }

        // --- Kiểm tra 2: trong 1 ngày tổng số ngày giường không được > 1 ---
        const byDay = {};
        for (const { dateKey, soNgayGiuong, item } of listWithSoNgay) {
            if (!dateKey) continue;
            byDay[dateKey] = (byDay[dateKey] || 0) + soNgayGiuong;
        }
        const ngayVuot = Object.entries(byDay).filter(([, sum]) => sum > 1);
        console.log('[Rule_Id_21] Tổng số ngày giường theo từng ngày (byDay):', JSON.stringify(byDay));
        console.log('[Rule_Id_21] Các ngày có tổng > 1 (ngayVuot):', ngayVuot.length ? ngayVuot : 'không có');
        if (ngayVuot.length > 0) {
            console.log('[Rule_Id_21] Kiểm tra 2 FAIL: có ngày tổng số ngày giường > 1');
            result.isValid = false;
            const ngayVuotSet = new Set(ngayVuot.map(([k]) => k));
                listWithSoNgay.forEach(({ dateKey, item: wrap }) => {
                if (ngayVuotSet.has(dateKey)) {
                    const dv = wrap.item || wrap;
                    result.errors.push(formatError(dv.id || dv.Id, `Trong cùng một ngày (${dateKey}) có nhiều hơn 1 dịch vụ nhóm 15, tổng số ngày giường > 1`));
                }
            });
        } else {
            console.log('[Rule_Id_21] Kiểm tra 2 PASS: không có ngày nào tổng số ngày giường > 1');
        }

        console.log('[Rule_Id_21] Kết quả: isValid =', result.isValid, '| errors:', result.errors.length);
    } catch (error) {
        console.log('[Rule_Id_21] Exception:', error.message);
        result.isValid = false;
        result.errors.push(formatError(null, `Lỗi khi kiểm tra số ngày điều trị và số ngày giường: ${error.message}`));
        result.message = 'Lỗi khi validate số ngày điều trị và số ngày giường';
    }

    return result;
};

module.exports = validateRule_Id_21;
