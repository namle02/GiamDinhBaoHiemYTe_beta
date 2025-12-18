/**
 * Rule 34: Kiểm tra dịch vụ phẫu thuật có khoảng thời gian giao nhau
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
   * Kiểm tra 2 khoảng thời gian có giao nhau không
   * Khoảng thời gian 1: [start1, end1]
   * Khoảng thời gian 2: [start2, end2]
   * Giao nhau nếu: start1 <= end2 && start2 <= end1
   */
  function isTimeRangeOverlap(service1, service2) {
    const start1 = parseCustomDate(service1.Ngay_Th_Yl);
    const end1 = parseCustomDate(service1.Ngay_Kq);
    const start2 = parseCustomDate(service2.Ngay_Th_Yl);
    const end2 = parseCustomDate(service2.Ngay_Kq);

    // Nếu thiếu thông tin ngày thì không thể kiểm tra
    if (!start1 || !end1 || !start2 || !end2) {
      return false;
    }

    // Kiểm tra overlap: start1 <= end2 && start2 <= end1
    return start1 <= end2 && start2 <= end1;
  }

  /**
   * Kiểm tra 2 dịch vụ có diễn ra và kết thúc đồng thời không
   */
  function isSimultaneous(service1, service2) {
    const start1 = parseCustomDate(service1.Ngay_Th_Yl);
    const end1 = parseCustomDate(service1.Ngay_Kq);
    const start2 = parseCustomDate(service2.Ngay_Th_Yl);
    const end2 = parseCustomDate(service2.Ngay_Kq);

    if (!start1 || !end1 || !start2 || !end2) {
      return false;
    }

    // Diễn ra và kết thúc đồng thời nếu Ngay_Th_Yl và Ngay_Kq đều giống nhau
    return start1.getTime() === start2.getTime() && end1.getTime() === end2.getTime();
  }

  try {
    // Lọc các dịch vụ phẫu thuật: ma_nhom === 8 và Ma_Pttt_Qt != null
    const surgeryServices = (patientData.Xml3 || []).filter(
      (item) =>
        item.Ma_Nhom == 8 &&
        item.Ma_Pttt_Qt != null 
    );

    // Kiểm tra từng cặp dịch vụ xem có giao nhau không
    for (let i = 0; i < surgeryServices.length; i++) {
      for (let j = i + 1; j < surgeryServices.length; j++) {
        const service1 = surgeryServices[i];
        const service2 = surgeryServices[j];

        // Chỉ kiểm tra nếu hai dịch vụ có khoảng thời gian giao nhau
        if (isTimeRangeOverlap(service1, service2)) {
          const start1 = parseCustomDate(service1.Ngay_Th_Yl);
          const start2 = parseCustomDate(service2.Ngay_Th_Yl);
          const tyle1 = parseFloat(service1.Tyle_Tt_Dv);
          const tyle2 = parseFloat(service2.Tyle_Tt_Dv);

          // Kiểm tra nếu hai dịch vụ diễn ra và kết thúc đồng thời
          if (isSimultaneous(service1, service2)) {
            // Một trong hai dịch vụ không được có Tyle_Tt_Dv = 100
            if (tyle1 === 100 || tyle2 === 100) {
              const errorIds = [];
              const errorMessages = [];
              
              if (tyle1 === 100) {
                errorIds.push(service1.Id);
                errorMessages.push(`Dịch vụ phẫu thuật (ID: ${service1.Id}) có Tỷ lệ thanh toán (Tyle_Tt_Dv) = 100 không hợp lệ khi diễn ra và kết thúc đồng thời với dịch vụ khác (ID: ${service2.Id})`);
              }
              
              if (tyle2 === 100) {
                errorIds.push(service2.Id);
                errorMessages.push(`Dịch vụ phẫu thuật (ID: ${service2.Id}) có Tỷ lệ thanh toán (Tyle_Tt_Dv) = 100 không hợp lệ khi diễn ra và kết thúc đồng thời với dịch vụ khác (ID: ${service1.Id})`);
              }

              result.errors.push({
                Ids: errorIds.length === 1 ? errorIds[0] : errorIds,
                Error: errorMessages.join("; "),
              });
              result.isValid = false;
            }
          } else {
            // Xác định dịch vụ nào diễn ra trước, dịch vụ nào diễn ra sau
            let earlierService, laterService;
            if (start1 <= start2) {
              earlierService = service1;
              laterService = service2;
            } else {
              earlierService = service2;
              laterService = service1;
            }

            const laterTyLe = parseFloat(laterService.Tyle_Tt_Dv);
            
            // Dịch vụ diễn ra sau có Tyle_Tt_Dv = 100 thì sai
            if (laterTyLe === 100) {
              result.errors.push({
                Id: laterService.Id,
                Error: `Dịch vụ phẫu thuật (ID: ${laterService.Id}) có Tỷ lệ thanh toán (Tyle_Tt_Dv) = 100 không hợp lệ vì diễn ra sau dịch vụ phẫu thuật khác (ID: ${earlierService.Id}) có khoảng thời gian giao nhau. Dịch vụ ${earlierService.Id}: từ ${earlierService.Ngay_Th_Yl} đến ${earlierService.Ngay_Kq}, Dịch vụ ${laterService.Id}: từ ${laterService.Ngay_Th_Yl} đến ${laterService.Ngay_Kq}`,
              });
              result.isValid = false;
            }
          }
        }
      }
    }
  } catch (error) {
    result.isValid = false;
    result.errors.push(
      `Lỗi khi validate dịch vụ phẫu thuật có khoảng thời gian giao nhau: ${error.message}`
    );
    result.message = "Lỗi khi validate dịch vụ phẫu thuật có khoảng thời gian giao nhau";
  }
  return result;
};

module.exports = validateRule_Id_34;
