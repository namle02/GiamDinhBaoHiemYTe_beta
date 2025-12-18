/**
 * Rule 4: Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ)
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const { GoogleGenAI } = require("@google/genai");
const ai = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY });

// Danh sách mã dịch vụ đặt ống thông niệu quản (dịch vụ đi kèm)
const danhSachDichVuDatOngNieuQuan = [
    "20.0083.0104", // Đặt ống thông niệu quản qua nội soi (sonde JJ)
    "10.0335.0104", // Đặt ống thông JJ trong hẹp niệu quản
    "02.0190.0104"  // Đặt ống thông niệu quản qua nội soi (sonde JJ)
];

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
 * Tạo prompt cho Gemini để xác định vị trí tán sỏi và đặt sonde JJ
 * @param {string} trinhTuText - Nội dung trình tự thực hiện (đã parse từ RTF)
 * @returns {string}
 */
const makeGeminiPrompt = (trinhTuText) => `
Dưới đây là trình tự thực hiện của một thủ thuật nội soi tiết niệu:

---
${trinhTuText}
---

Hãy phân tích và xác định:
1. Vị trí tán sỏi niệu quản (phải/trái/cả hai/không xác định)
2. Vị trí đặt sonde JJ/ống thông niệu quản (phải/trái/cả hai/không xác định)

Quy tắc trả lời:
- Chỉ trả lời đúng định dạng JSON như sau, không giải thích thêm:
{"viTriTanSoi": ["phải"], "viTriDatSondeJJ": ["phải"]}
- Nếu cả hai bên thì: {"viTriTanSoi": ["phải", "trái"], "viTriDatSondeJJ": ["phải", "trái"]}
- Nếu không xác định được thì trả về mảng rỗng: {"viTriTanSoi": [], "viTriDatSondeJJ": []}
`;

const validateRule_Id_4 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ)',
        ruleId: 'Rule_Id_4',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile: 'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        
        // Tìm các dịch vụ tán sỏi niệu quản (mã 20.0084.0440) - chỉ dịch vụ này có TrinhTuThucHien
        const danhSachDichVuTanSoi = xml3_data.filter(
            item => item.TrinhTuThucHien && item.Ma_Dich_Vu === '20.0084.0440'
        );
        
        // Tìm các dịch vụ đặt ống thông niệu quản (dịch vụ đi kèm)
        const danhSachDichVuDatOng = xml3_data.filter(
            item => danhSachDichVuDatOngNieuQuan.includes(item.Ma_Dich_Vu)
        );
        
        // Nếu không có dịch vụ tán sỏi hoặc không có dịch vụ đặt ống thì không cần kiểm tra
        if (danhSachDichVuTanSoi.length === 0 || danhSachDichVuDatOng.length === 0) {
            return result;
        }
        
        // Xử lý từng dịch vụ tán sỏi
        for (const dichVuTanSoi of danhSachDichVuTanSoi) {
            const textTrinhTu = parseRtfToString(dichVuTanSoi.TrinhTuThucHien);
            
            if (!textTrinhTu) {
                continue;
            }

            // Sử dụng Gemini API để xác định vị trí
            const prompt = makeGeminiPrompt(textTrinhTu);
            
            let viTriTanSoi = [];
            let viTriDatSondeJJ = [];
            
            try {
                const response = await ai.models.generateContent({
                    model: "gemini-2.5-flash",
                    contents: [{ role: "user", parts: [{ text: prompt }] }],
                });

                const responseText = response?.response?.candidates?.[0]?.content?.parts?.[0]?.text
                    || response.text
                    || "";

                console.log(responseText);
                // Parse JSON từ response
                const jsonMatch = responseText.match(/\{[^}]+\}/);
                if (jsonMatch) {
                    try {
                        const parsed = JSON.parse(jsonMatch[0]);
                        if (Array.isArray(parsed.viTriTanSoi)) {
                            viTriTanSoi = parsed.viTriTanSoi.map(s => s.toLowerCase().trim());
                        }
                        if (Array.isArray(parsed.viTriDatSondeJJ)) {
                            viTriDatSondeJJ = parsed.viTriDatSondeJJ.map(s => s.toLowerCase().trim());
                        }
                    } catch {
                        // JSON parse error - fallback
                    }
                }
            } catch (err) {
                // Nếu lỗi Gemini thì warning chứ không fail hard rule
                result.warnings.push(
                    `Không thể phân tích trình tự thực hiện bằng AI cho dịch vụ ${dichVuTanSoi.Ma_Dich_Vu}: ${err.message}`
                );
                continue;
            }
            
            if (viTriTanSoi.length === 0 || viTriDatSondeJJ.length === 0) {
                // Không xác định được vị trí, bỏ qua
                continue;
            }
            
            // Kiểm tra xem vị trí tán sỏi và vị trí đặt sonde JJ có trùng nhau không
            const viTriTrung = viTriTanSoi.filter(vt => viTriDatSondeJJ.includes(vt));
            
            if (viTriTrung.length > 0) {
                // Có vị trí trùng nhau -> báo lỗi cho cả dịch vụ tán sỏi và các dịch vụ đặt ống thông
                result.isValid = false;
                const viTriStr = viTriTrung.join(', ');
                
                // Báo lỗi cho dịch vụ tán sỏi
                result.errors.push({
                    Id: dichVuTanSoi.Id,
                    Error: `Dịch vụ tán sỏi niệu quản (${dichVuTanSoi.Ma_Dich_Vu}) và dịch vụ đặt ống thông đều thực hiện ở bên ${viTriStr}. Không được thanh toán đồng thời dịch vụ đặt ống thông niệu quản khi đã thanh toán dịch vụ nội soi tán sỏi niệu quản cùng bên.`
                });
                
                // Báo lỗi cho các dịch vụ đặt ống thông
                for (const dichVuDatOng of danhSachDichVuDatOng) {
                    result.errors.push({
                        Id: dichVuDatOng.Id,
                        Error: `Dịch vụ tán sỏi niệu quản (${dichVuTanSoi.Ma_Dich_Vu}) và dịch vụ đặt ống thông (${dichVuDatOng.Ma_Dich_Vu}) đều thực hiện ở bên ${viTriStr}. Không được thanh toán thêm dịch vụ đặt ống thông niệu quản khi đã thanh toán dịch vụ nội soi tán sỏi niệu quản cùng bên.`
                    });
                }
            }
        }
        
        if (!result.isValid) {
            result.message = 'Phát hiện dịch vụ đặt ống thông niệu quản (sonde JJ) được thanh toán cùng bên với dịch vụ nội soi tán sỏi niệu quản';
        }
        
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Rule_Id_4: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại';
    }

    return result;
};

module.exports = validateRule_Id_4;
