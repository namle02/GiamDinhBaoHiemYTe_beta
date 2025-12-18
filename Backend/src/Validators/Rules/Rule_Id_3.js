/**
 * Rule 3: Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const { GoogleGenAI } = require("@google/genai");
const ai = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY });

const ds_dichvu = [
    "02.0307.0136",
    "02.0262.0136",
    "02.0306.0137",
    "02.0259.0137",
    "03.1066.0136",
    "03.1062.0137",
    "20.0073.0136",
    "20.0081.0137",
    "02.0309.0138",
    "02.0293.0138",
    "02.0256.0139",
    "02.0308.0139",
    "02.0310.0506",
    "02.0295.0498",
    "02.0296.0500",
    "02.0286.0497"
]

const regionKeywords = [
    "đại tràng",
    "trực tràng"
]

const makeGeminiPrompt = (mo_ta_text) => `
Dưới đây là kết quả mô tả nội soi của bệnh nhân:

---
${mo_ta_text}
---

Hãy liệt kê các vùng nào trong số: "đại tràng", "trực tràng" có xuất hiện u hoặc có bất thường. 
Quy tắc: Trả lời duy nhất một mảng các vùng bị u, không giải thích gì thêm, không thêm thông tin khác, ví dụ: ["đại tràng", "trực tràng"], hoặc nếu không có thì trả lời: []
`;

const validateRule_Id_3 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm',
        ruleId: 'Rule_Id_3',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];

        // Tìm các dịch vụ thuộc ds_dichvu có mo_ta_text
        const dichVuLienQuan = xml3_data.filter(
          (dv) => ds_dichvu.includes(dv.Ma_Dich_Vu) && typeof dv.Mo_Ta_Text === "string" && dv.Mo_Ta_Text.trim()
        );
    
        for (const dv of dichVuLienQuan) {
          const mo_ta_text = dv.Mo_Ta_Text;
          const prompt = makeGeminiPrompt(mo_ta_text);
    
          let response, text, regions = [];
          try {
            response = await ai.models.generateContent({
              model: "gemini-2.5-flash",
              contents: [{ role: "user", parts: [{ text: prompt }] }],
            });
    
            text = response?.response?.candidates?.[0]?.content?.parts?.[0]?.text
              || response.text
              || "";
    
            // Clean up & parse regions
            const matchedArr = text.match(/\[[^\]]*\]/);
            if (matchedArr) {
              try {
                const candidates = JSON.parse(matchedArr[0]);
                console.log(candidates);
                if (Array.isArray(candidates)) regions = candidates.map(s => s.toLowerCase().trim());
              } catch { /* JSON parse error - fallback below */ }
            }
    
            // Nếu parsing JSON thất bại, thử đọc thủ công
            if (!Array.isArray(regions) || regions.length === 0) {
              regionKeywords.forEach(region => {
                if (text.toLowerCase().includes(region)) regions.push(region);
              });
            }
          } catch (err) {
            // Nếu lỗi Gemini thì warning chứ không fail hard rule
            result.warnings.push(
              `Không thể phân tích mô tả bằng AI cho dịch vụ ${dv.Ma_Dich_Vu}: ${err.message}`
            );
            continue;
          }
    
          // Kiểm tra vùng bị u
          const regionsBiU = regions.filter(region =>
            regionKeywords.includes(region)
          );
    
          if (regionsBiU.length > 0) {
            result.isValid = false;
            result.errors.push(
              {
                Id: dv.Id,
                Error: `Dịch vụ mã ${dv.Ma_Dich_Vu} ghi nhận vùng bị u: ${regionsBiU.join(", ")}. Không được thanh toán thêm dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm.`
              });
          }
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ can thiệp ống tiêu hóa, không thanh toán thêm dịch vụ Nội soi đại trực tràng toàn bộ ống mềm';
    }

    return result;
};

module.exports = validateRule_Id_3;