/**
 * Rule 11: Xét nghiệm “Định lượng Pro-calcitonin [Máu]” chỉ định không đúng khoảng cách hoặc xét nghiệm “Định lượng CRP/CRPhs” thanh toán đồng thời với “Định lượng Pro-calcitonin [Máu]” không đúng quy định tại Thông tư số 50/2017/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_11 = (patientData) => {
    const result = {
        ruleName: 'Xét nghiệm “Định lượng Pro-calcitonin [Máu]” chỉ định không đúng khoảng cách hoặc xét nghiệm “Định lượng CRP/CRPhs” thanh toán đồng thời với “Định lượng Pro-calcitonin [Máu]” không đúng quy định tại Thông tư số 50/2017/TT-BYT',
        ruleId: 'Rule_Id_11',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        // Lọc ra các dịch vụ cần kiểm tra
        const procalcitoninList = [];
        const crpList = [];
        for (const item of xml3_data) {
            if (item.Ma_Dich_Vu === '23.0130.1549' && item.Ngay_Yl) {
                procalcitoninList.push(item);
            }
            if (item.Ma_Dich_Vu === '23.0050.1484' && item.Ngay_Yl) {
                crpList.push(item);
            }
        }

        // Nếu có cả 2 mã dịch vụ
        if (procalcitoninList.length > 0 && crpList.length > 0) {
            // Kiểm tra từng lần chỉ định Pro-calcitonin
            for (const proItem of procalcitoninList) {
                // Ngày YL dạng 202412250300
                const ngayYlStr = proItem.Ngay_Yl;
                // Chuyển đổi sang đối tượng Date
                const year = parseInt(ngayYlStr.substring(0, 4), 10);
                const month = parseInt(ngayYlStr.substring(4, 6), 10) - 1; // Tháng trong JS bắt đầu từ 0
                const day = parseInt(ngayYlStr.substring(6, 8), 10);
                const hour = parseInt(ngayYlStr.substring(8, 10), 10);
                const minute = parseInt(ngayYlStr.substring(10, 12), 10);
                const proDate = new Date(year, month, day, hour, minute);

                // Tìm các lần chỉ định Pro-calcitonin khác để so sánh khoảng cách
                for (const otherProItem of procalcitoninList) {
                    if (otherProItem === proItem) continue;
                    const otherNgayYlStr = otherProItem.Ngay_Yl;
                    const oYear = parseInt(otherNgayYlStr.substring(0, 4), 10);
                    const oMonth = parseInt(otherNgayYlStr.substring(4, 6), 10) - 1;
                    const oDay = parseInt(otherNgayYlStr.substring(6, 8), 10);
                    const oHour = parseInt(otherNgayYlStr.substring(8, 10), 10);
                    const oMinute = parseInt(otherNgayYlStr.substring(10, 12), 10);
                    const otherProDate = new Date(oYear, oMonth, oDay, oHour, oMinute);

                    // Tính khoảng cách giữa 2 lần chỉ định (tính bằng giờ)
                    const diffMs = Math.abs(proDate - otherProDate);
                    const diffHours = diffMs / (1000 * 60 * 60);

                    if (diffHours < 48) {
                        result.isValid = false;
                        result.errors.push(
                            { Id: proItem.Id, Error: `Có đồng thời cả 2 mã dịch vụ 23.0130.1549 và 23.0050.1484, nhưng các lần chỉ định Pro-calcitonin [Máu] có khoảng cách nhỏ hơn 48h (Ngày chỉ định: ${ngayYlStr} và ${otherNgayYlStr})` }
                        );
                        result.message = 'Phát hiện chỉ định Pro-calcitonin [Máu] không đúng khoảng cách 48h khi đồng thời có chỉ định CRP/CRPhs.';
                        // Có thể break nếu chỉ cần báo lỗi 1 lần
                        break;
                    }
                }
                if (!result.isValid) break;
            }
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi kiểm tra logic dịch vụ Pro-calcitonin và CRP/CRPhs: ${error.message}`);
        result.message = 'Lỗi khi validate dịch vụ Pro-calcitonin và CRP/CRPhs';
    }

    return result;
};

module.exports = validateRule_Id_11;