/**
 * Rule 21: Thanh toán số ngày giường điều trị nội trú không đúng quy định tại điểm a và điểm b khoản 1 Điều 6 Thông tư số 22/2023/TT-BYT.
 * - Lấy tất cả dịch vụ Ma_Nhom = 15, cộng So_Luong để ra tổng số ngày giường thực tế.
 * - Số ngày giường mong muốn lấy theo (Ngày ra - Ngày vào):
 *   + < 4 giờ: 0
 *   + từ 4 giờ đến 24 giờ: 1
 *   + > 24 giờ: ceil(số giờ/24)
 * - Nếu Ket_Qua_Dtri = 4 hoặc 5 thì số ngày giường mong muốn = (Ngày ra - Ngày vào) + 1.
 * - Trong 1 ngày (theo Ngay_yl), tổng So_Luong dịch vụ nhóm 15 không được > 1.
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

function toNumber(value) {
    if (value == null) return 0;
    if (typeof value === 'number') return Number.isFinite(value) ? value : 0;
    if (typeof value === 'object' && typeof value.toString === 'function') {
        const n = Number(value.toString());
        return Number.isFinite(n) ? n : 0;
    }
    const n = Number(value);
    return Number.isFinite(n) ? n : 0;
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
        const xml1 = patientData.Xml1 && patientData.Xml1[0] ? patientData.Xml1[0] : {};
        const xml3 = patientData.Xml3 || [];

        const dichVuNhom15 = xml3.filter(item => item.Ma_Nhom == '15');
        if (dichVuNhom15.length === 0) {
            return result;
        }

        const ngayRaStr = getEffectiveNgayRa(xml1);
        const ngayVaoStr = xml1.Ngay_Vao ?? xml1.Ngay_vao ?? '';

        const ngayRa = parseDate(ngayRaStr);
        const ngayVao = parseDate(ngayVaoStr);

        let expectedSoNgayGiuong = 0;
        if (ngayRa && ngayVao) {
            const diffMs = Math.max(0, ngayRa.getTime() - ngayVao.getTime());
            const diffHours = diffMs / (1000 * 60 * 60);
            let soNgayTheoThoiGian = 0;

            if (diffHours < 4) {
                soNgayTheoThoiGian = 0;
            } else if (diffHours <= 24) {
                soNgayTheoThoiGian = 1;
            } else {
                soNgayTheoThoiGian = Math.ceil(diffHours / 24);
            }

            const ketQuaDtri = xml1.Ket_Qua_Dtri ?? xml1.ket_qua_Dtri;
            const is4or5 = Number(ketQuaDtri) === 4 || Number(ketQuaDtri) === 5;
            expectedSoNgayGiuong = is4or5 ? soNgayTheoThoiGian + 1 : soNgayTheoThoiGian;
        }

        // --- Tổng số ngày giường thực tế: cộng So_Luong của toàn bộ dịch vụ nhóm 15 ---
        const listWithSoLuong = dichVuNhom15.map(dv => {
            const soLuong = toNumber(dv.So_Luong ?? dv.so_luong);
            const start = parseDate(dv.Ngay_yl ?? dv.Ngay_Yl ?? '');
            let dateKey = '';
            if (start) {
                const y = start.getFullYear();
                const m = String(start.getMonth() + 1).padStart(2, '0');
                const day = String(start.getDate()).padStart(2, '0');
                dateKey = `${y}${m}${day}`;
            }
            return { item: dv, soLuong, dateKey };
        });

        const totalSoNgayGiuong = listWithSoLuong.reduce((s, x) => s + x.soLuong, 0);

        // --- Kiểm tra 1: tổng số ngày giường thực tế phải bằng số ngày giường mong muốn ---
        if (expectedSoNgayGiuong !== totalSoNgayGiuong) {
            result.isValid = false;
            const ketQuaDtri = xml1.Ket_Qua_Dtri ?? xml1.ket_qua_Dtri;
            const is4or5 = Number(ketQuaDtri) === 4 || Number(ketQuaDtri) === 5;
            const msg = `Tổng số ngày giường theo So_Luong dịch vụ nhóm 15 (${totalSoNgayGiuong}) không bằng số ngày giường mong muốn theo ngày ra - ngày vào${is4or5 ? ' + 1 (do Ket_Qua_Dtri = 4/5)' : ''} = ${expectedSoNgayGiuong}`;
            dichVuNhom15.forEach(item => {
                result.errors.push(formatError(item.id || item.Id, msg));
            });
        }

        // --- Kiểm tra 2: trong 1 ngày tổng So_Luong không được > 1 ---
        const byDay = {};
        for (const { dateKey, soLuong } of listWithSoLuong) {
            if (!dateKey) continue;
            byDay[dateKey] = (byDay[dateKey] || 0) + soLuong;
        }
        const ngayVuot = Object.entries(byDay).filter(([, sum]) => sum > 1);
        if (ngayVuot.length > 0) {
            result.isValid = false;
            const ngayVuotSet = new Set(ngayVuot.map(([k]) => k));
            listWithSoLuong.forEach(({ dateKey, item }) => {
                if (ngayVuotSet.has(dateKey)) {
                    result.errors.push(formatError(item.id || item.Id, `Trong cùng một ngày (${dateKey}) tổng số ngày giường (tổng So_Luong của nhóm 15) lớn hơn 1`));
                }
            });
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push(formatError(null, `Lỗi khi kiểm tra số ngày điều trị và số ngày giường: ${error.message}`));
        result.message = 'Lỗi khi validate số ngày điều trị và số ngày giường';
    }

    return result;
};

module.exports = validateRule_Id_21;
