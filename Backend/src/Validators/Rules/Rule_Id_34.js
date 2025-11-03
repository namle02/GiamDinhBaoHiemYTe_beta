/**
 * Rule 34: Sai tỷ lệ thanh toán PT thứ 2
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_34 = async (patientData) => {
  const result = {
    ruleName: "Sai tỷ lệ thanh toán PT thứ 2",
    ruleId: "Rule_Id_34",
    isValid: true,
    validateField: "Ma_Dich_Vu",
    validateFile: "XML3",
    message: "",
    errors: [],
    warnings: [],
  };

  /**
   * Parse date string in format "YYYYMMDDHHmm" (e.g., 202501181224) to Date
   */
  function parseCustomDate(str) {
    if (!str || typeof str !== "string" || str.length < 8) return null;
    // When length >= 12, parse as YYYYMMDDHHmm, else just date
    const year = Number(str.substr(0, 4));
    const month = Number(str.substr(4, 2)) - 1;
    const day = Number(str.substr(6, 2));
    const hour = str.length >= 10 ? Number(str.substr(8, 2)) : 0;
    const min = str.length >= 12 ? Number(str.substr(10, 2)) : 0;
    return new Date(year, month, day, hour, min, 0, 0);
  }

  /**
   * Kiểm tra 2 ngày có là cùng ngày hoặc liền ngày không
   * So sánh chỉ theo yyyy-mm-dd (đúng ngày); liền kề nghĩa là cách đúng 1 ngày
   */
  function isConsecutiveOrSameDay(dateStr1, dateStr2) {
    const d1 = parseCustomDate(dateStr1);
    const d2 = parseCustomDate(dateStr2);
    if (!d1 || !d2 || isNaN(d1) || isNaN(d2)) return false;
    // Loại bỏ thời gian
    d1.setHours(0, 0, 0, 0);
    d2.setHours(0, 0, 0, 0);
    const diff = Math.abs(d1 - d2);
    return diff === 0 || diff === 86400000;
  }

  try {
    const xml3_data = (patientData.Xml3 || []).filter(
      (item) => item.Ma_Pttt_Qt != null && item.Ma_Pttt_Qt !== ""
    );

    // Sắp xếp theo ngày chỉ định tăng dần (Ngay_Th_Yl)
    const sortedServices = [...xml3_data].sort((a, b) => {
      const dateA = a.Ngay_Th_Yl ? parseCustomDate(a.Ngay_Th_Yl) : new Date(0);
      const dateB = b.Ngay_Th_Yl ? parseCustomDate(b.Ngay_Th_Yl) : new Date(0);
      return dateA - dateB;
    });


    for (let i = 0; i < sortedServices.length - 1; i++) {
      const first = sortedServices[i];
      const second = sortedServices[i + 1];
      // Dịch vụ liền kề nếu ngày y lệnh của dịch vụ 1 liền kề ngày kết quả của dịch vụ 2
      if (first.Ngay_Th_Yl && second.Ngay_Kq && isConsecutiveOrSameDay(first.Ngay_Th_Yl, second.Ngay_Kq)) {
        // Kiểm tra tỷ lệ thanh toán
        // Dịch vụ đầu tiên phải có Tyle_Tt_Dv là 100
        if (parseFloat(first.Tyle_Tt_Dv) !== 100) {
          result.errors.push({
            Id: first.Id,
            Error: `Dịch vụ phẫu thuật đầu tiên (ID: ${first.Id}) có Tỷ lệ thanh toán (Tyle_Tt_Dv) sai: ${first.Tyle_Tt_Dv}, phải là 100 khi liền kề với dịch vụ phẫu thuật tiếp theo (ID: ${second.Id})`,
          });
          result.isValid = false;
          console.log(result.isValid);
        }

        // Dịch vụ thứ hai
        let expectedTyLe =
          first.Ma_Bac_Si &&
          second.Ma_Bac_Si &&
          first.Ma_Bac_Si === second.Ma_Bac_Si
            ? 50
            : 80;
        if (parseFloat(second.Tyle_Tt_Dv) !== expectedTyLe) {
          result.errors.push({
            Id: second.Id,
            Error: `Dịch vụ phẫu thuật tiếp theo (ID: ${
              second.Id
            }) có Tỷ lệ thanh toán (Tyle_Tt_Dv) sai: ${
              second.Tyle_Tt_Dv
            }, phải là ${expectedTyLe} vì ${
              first.Ma_Bac_Si === second.Ma_Bac_Si ? "cùng" : "khác"
            } bác sĩ với dịch vụ trước (ID: ${first.Id})`,
          });
          result.isValid = false;
        }
      }
    }

  } catch (error) {
    result.isValid = false;
    result.errors.push(
      `Lỗi khi validate Sai tỷ lệ thanh toán PT thứ 2: ${error.message}`
    );
    result.message = "Lỗi khi validate Sai tỷ lệ thanh toán PT thứ 2";
  } 
  return result;
};

module.exports = validateRule_Id_34;
