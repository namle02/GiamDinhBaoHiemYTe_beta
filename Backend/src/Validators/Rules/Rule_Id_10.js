/**
 * Rule 10: Thanh toán "Xét nghiệm sinh thiết tức thì bằng cắt lạnh" không đúng quy định tại Quyết định số 3338/QĐ-BYT quy trình kỹ thuật khám bệnh, chữa bệnh chuyên ngành Ung bướu và Quyết định số 5199/QĐ-BYT quy trình kỹ thuật chuyênngành Giải phẫu bệnh - tế bào học.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_10 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán "Xét nghiệm sinh thiết tức thì bằng cắt lạnh" không đúng quy định tại Quyết định số 3338/QĐ-BYT quy trình kỹ thuật khám bệnh, chữa bệnh chuyên ngành Ung bướu và Quyết định số 5199/QĐ-BYT quy trình kỹ thuật chuyênngành Giải phẫu bệnh - tế bào học.',
        ruleId: 'Rule_Id_10',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
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
     * Kiểm tra xem dịch vụ có Ma_Dich_Vu = 25.0090.1757 có nằm trong khoảng thời gian
     * (từ Ngay_Th_Yl đến Ngay_Kq) của dịch vụ có Ma_Nhom = 8 không
     * @param {Object} dichVu1757 - Dịch vụ có Ma_Dich_Vu = 25.0090.1757
     * @param {Object} dichVuNhom8 - Dịch vụ có Ma_Nhom = 8
     * @param {Boolean} debug - Có in debug log không
     * @returns {Boolean} - true nếu dịch vụ 1757 nằm trong khoảng thời gian của dịch vụ nhóm 8
     */
    function isWithinTimeRange(dichVu1757, dichVuNhom8) {
        const start1757 = parseCustomDate(dichVu1757.Ngay_Th_Yl);
        const end1757 = parseCustomDate(dichVu1757.Ngay_Kq);
        const startNhom8 = parseCustomDate(dichVuNhom8.Ngay_Th_Yl);
        const endNhom8 = parseCustomDate(dichVuNhom8.Ngay_Kq);

        // Nếu thiếu thông tin ngày thì không thể kiểm tra
        if (!start1757 || !end1757 || !startNhom8 || !endNhom8) {
            return false;
        }

        // Kiểm tra xem khoảng thời gian của dịch vụ 1757 có nằm trong khoảng thời gian của dịch vụ nhóm 8 không
        // Dịch vụ 1757 nằm giữa khoảng thời gian thực hiện của dịch vụ nhóm 8 nếu có giao nhau:
        // start1757 <= endNhom8 && startNhom8 <= end1757
        // Điều này đảm bảo rằng ít nhất một phần của dịch vụ 1757 nằm trong khoảng thời gian của dịch vụ nhóm 8
        const isOverlap = start1757 <= endNhom8 && startNhom8 <= end1757;
        
        return isOverlap;
    }

    try {
        const xml3_data = patientData.Xml3 || [];

        if (!Array.isArray(xml3_data)) {
            throw new Error('Dữ liệu XML3 không hợp lệ hoặc thiếu');
        }

        // Lấy tất cả dịch vụ có Ma_Nhom = 8
        const dichVuNhom8 = xml3_data.filter(item => item.Ma_Nhom == 8);

        // Lấy tất cả dịch vụ có Ma_Dich_Vu = 25.0090.1757
        const dichVu1757 = xml3_data.filter(item => item.Ma_Dich_Vu === '25.0090.1757');

        // Kiểm tra từng dịch vụ có Ma_Dich_Vu = 25.0090.1757
        for (const dv1757 of dichVu1757) {
            let coNamTrongKhoangThoiGian = false;

            // Kiểm tra xem dịch vụ này có nằm trong khoảng thời gian của bất kỳ dịch vụ nào có Ma_Nhom = 8 không
            for (let i = 0; i < dichVuNhom8.length; i++) {
                const dvNhom8 = dichVuNhom8[i];
                const isWithin = isWithinTimeRange(dv1757, dvNhom8);
                if (isWithin) {
                    coNamTrongKhoangThoiGian = true;
                    break;
                }
            }

            // Nếu dịch vụ 1757 không nằm trong khoảng thời gian của bất kỳ dịch vụ nào có Ma_Nhom = 8 thì sai
            if (!coNamTrongKhoangThoiGian) {
                result.isValid = false;
                result.errors.push({
                    Id: dv1757.id || dv1757.Id,
                    Error: `Dịch vụ "Xét nghiệm sinh thiết tức thì bằng cắt lạnh" (Ma_Dich_Vu: 25.0090.1757) không nằm trong khoảng thời gian thực hiện của dịch vụ có Ma_Nhom = 8. Ngày thực hiện dịch vụ: từ ${dv1757.Ngay_Th_Yl} đến ${dv1757.Ngay_Kq}`
                });
            }
        }

        if (result.errors.length > 0) {
            result.isValid = false;
            result.message = 'Có dịch vụ "Xét nghiệm sinh thiết tức thì bằng cắt lạnh" không nằm trong khoảng thời gian thực hiện của dịch vụ có Ma_Nhom = 8';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi kiểm tra dịch vụ "Xét nghiệm sinh thiết tức thì bằng cắt lạnh": ${error.message}`);
        result.message = 'Lỗi khi validate dịch vụ "Xét nghiệm sinh thiết tức thì bằng cắt lạnh"';
    }

    return result;
};

module.exports = validateRule_Id_10;