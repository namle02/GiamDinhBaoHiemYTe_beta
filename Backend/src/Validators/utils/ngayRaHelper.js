/**
 * Helper cho Ngay_Ra từ XML1.
 * Quy ước: Mỗi rule có dùng Ngay_Ra từ xml1 phải lấy giá trị qua getEffectiveNgayRa(xml1).
 * - Nếu xml1.Ngay_Ra null/undefined/rỗng → trả về thời điểm xử lý (mốc hiện tại), format yyyyMMddHHmm.
 * - Nếu có giá trị → trả về Ngay_Ra như bình thường (string).
 * @param {Object} xml1 - Bản ghi XML1 (thường là patientData.Xml1[0])
 * @returns {string} - Ngày ra hiệu lực (yyyyMMddHHmm hoặc đủ độ dài như từ DB)
 */
function getEffectiveNgayRa(xml1) {
    const raw = xml1 && (xml1.Ngay_Ra ?? xml1.ngay_ra);
    if (raw != null && String(raw).trim() !== '') {
        return String(raw).trim();
    }
    const now = new Date();
    const y = now.getFullYear();
    const m = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    const h = String(now.getHours()).padStart(2, '0');
    const min = String(now.getMinutes()).padStart(2, '0');
    return `${y}${m}${d}${h}${min}`;
}

module.exports = { getEffectiveNgayRa };
