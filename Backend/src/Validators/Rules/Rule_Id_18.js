/**
 * Rule 18: Thanh toán dịch vụ "Phẫu thuật mở bụng cắt tử cung hoàn toàn và hai phần phụ", không thanh toán thêm dịch vụ "Phẫu thuật mở bụng cắt u buồng trứng hoặc cắt phần phụ" vì theo hướng dẫn của quy trình số 30 ban hành kèm theo Quyết định số 1377/QĐ-BYT Hướng dẫn Quy trình kỹ thuật khám bệnh, chữa bệnh chuyên ngành Phụ Sản thì "Phẫu thuật mở bụng cắt tử cung hoàn toàn là phẫu thuật cắt bỏ toàn bộ khối tử cung bao gồm thân tử cung, cổ tử cung, vòi tử cung, buồng trứng".
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const { GoogleGenAI } = require("@google/genai");
const ai = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY });

/**
 * Chuyển nội dung RTF về plain text.
 * @param {string} rtf
 * @returns {string}
 */
const parseRtfToString = (rtf = '') => {
    if (typeof rtf !== 'string' || !rtf.trim()) return '';

    let text = rtf;

    // Thay thế các control word \line \par bằng xuống dòng
    text = text.replace(/\\(line|par)\b/g, '\n');

    // Giải mã \uXXXX (Unicode) và bỏ phần fallback nếu có (\'xx)
    text = text.replace(/\\u(-?\d+)(?:'[0-9a-fA-F]{2})?/g, (_, num) => {
        let code = parseInt(num, 10);
        if (code < 0) code = 0x10000 + code;
        return String.fromCodePoint(code);
    });

    // Giải mã \'xx (hex)
    text = text.replace(/'[0-9a-fA-F]{2}/g, match => {
        const code = parseInt(match.slice(1), 16);
        return Number.isFinite(code) ? String.fromCharCode(code) : '';
    });

    // Bỏ control word/nhãn RTF còn lại và ngoặc { }
    text = text.replace(/\\[a-zA-Z*]+\d* ?/g, '').replace(/[{}]/g, '');

    // Unescape dấu gạch chéo
    text = text.replace(/\\([\\{}])/g, '$1');

    // Gom nhiều khoảng trắng/thừa xuống dòng
    return text.replace(/[ \t]+\n/g, '\n').replace(/\n{3,}/g, '\n\n').trim();
};

/**
 * Tạo prompt cho Gemini để xác định có "để lại phần lành" hay không
 * @param {string} trinhTuText - Nội dung trình tự thực hiện (đã parse từ RTF)
 * @returns {string}
 */
const makeGeminiPrompt = (trinhTuText) => `
Dưới đây là trình tự thực hiện của một ca phẫu thuật:

---
${trinhTuText}
---

Hãy phân tích và xác định xem trong trình tự thực hiện này có ghi rõ là "để lại phần lành" hoặc "để lại" một phần nào đó (ví dụ: để lại buồng trứng lành, để lại phần phụ lành, v.v.) hay không.

Quy tắc trả lời:
- Chỉ trả lời đúng định dạng JSON như sau, không giải thích thêm:
{"coDeLaiPhanLanh": true}
hoặc
{"coDeLaiPhanLanh": false}
- Trả về true nếu có ghi rõ "để lại phần lành" hoặc "để lại" một phần nào đó
- Trả về false nếu không có ghi nhận gì về việc "để lại"
`;

const validateRule_Id_18 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ “Phẫu thuật mở bụng cắt tử cung hoàn toàn và hai phần phụ”, không thanh toán thêm dịch vụ "Phẫu thuật mở bụng cắt u buồng trứng hoặc cắt phần phụ” vì theo hướng dẫn của quy trình số 30 ban hành kèm theo Quyết định số 1377/QĐ-BYT Hướng dẫn Quy trình kỹ thuật khám bệnh, chữa bệnh chuyên ngành Phụ Sản thì “Phẫu thuật mở bụng cắt tử cung hoàn toàn là phẫu thuật cắt bỏ toàn bộ khối tử cung bao gồm thân tử cung, cổ tử cung, vòi tử cung, buồng trứng”.',
        ruleId: 'Rule_Id_18',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        const DanhSachDichVuChinh = [
            '12.0292.0682',
            '13.0056.0682',
            '13.0068.0681',
            '13.0069.0681',
            '27.0428.0690',
            '12.0297.0661',
            '13.0059.0661'
        ];
        const DanhSachDichVuPhu = [
            '12.0281.0683',
            '12.0281.0683_GT',
            '13.0072.0683',
            '13.0072.0683_GT',
            '13.0080.0689',
            '13.0081.0689',
            '13.0083.0689',
            '27.0433.0689',
            '12.0300.0661'
        ];

        // Lấy danh sách mã dịch vụ đã sử dụng
        const maDichVuDaSuDung = xml3_data.map(item => item.Ma_Dich_Vu);

        // Kiểm tra có dịch vụ chính không
        const coDichVuChinh = DanhSachDichVuChinh.some(ma => maDichVuDaSuDung.includes(ma));
        // Kiểm tra có dịch vụ phụ không
        const coDichVuPhu = DanhSachDichVuPhu.some(ma => maDichVuDaSuDung.includes(ma));

        if (coDichVuChinh && coDichVuPhu) {
            result.isValid = false;
            xml3_data.forEach(item => {
                if (DanhSachDichVuPhu.includes(item.Ma_Dich_Vu)) {
                    result.errors.push({ Id: item.Id, Error: 'Không thanh toán đồng thời với phẫu thuật mở bụng cắt tử cung hoàn toàn (QĐ 1377/QĐ-BYT)' });
                }
            });
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi kiểm tra dịch vụ phẫu thuật: ${error.message}`);
        result.message = 'Lỗi khi validate dịch vụ phẫu thuật';
    }

    return result;
};

module.exports = validateRule_Id_18;