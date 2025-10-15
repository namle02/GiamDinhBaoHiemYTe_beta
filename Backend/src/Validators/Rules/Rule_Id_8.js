/**
 * Rule 8: Thanh toán DV Nội soi có sinh thiết (Nội soi thực quản dạ dày tá tràng, nội soi ổ bụng,...) nhưng không làm xét nghiệm giải phẫu mô bệnh học, điều chỉnh về mức giá của các DV nội soi không sinh thiết
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_8 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán DV Nội soi có sinh thiết (Nội soi thực quản dạ dày tá tràng, nội soi ổ bụng,...) nhưng không làm xét nghiệm giải phẫu mô bệnh học, điều chỉnh về mức giá của các DV nội soi không sinh thiết',
        ruleId: 'Rule_Id_8',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        const dsMaDichVu = xml3_data.map(item => item.Ma_Dich_Vu);
        const dsDichVuYeuCau = [
            '22.0133.1409',
            '25.0030.1751',
            '25.0090.1757'
        ];

        // Nếu có mã dịch vụ 02.0304.0134 thì phải có kèm theo 1 trong các mã trong danh sách dịch vụ yêu cầu
        if (dsMaDichVu.includes('02.0304.0134')) {
            const coDichVuYeuCau = dsDichVuYeuCau.some(ma => dsMaDichVu.includes(ma));
            if (!coDichVuYeuCau) {
                // Tìm tất cả các item có mã 02.0304.0134 để báo lỗi chi tiết
                xml3_data.forEach(item => {
                    if (item.Ma_Dich_Vu === '02.0304.0134') {
                        result.isValid = false;
                        result.errors.push({
                            Id: item.Id,
                            Error: `Dịch vụ nội soi có sinh thiết (02.0304.0134) phải kèm theo ít nhất một trong các dịch vụ yêu cầu: ${dsDichVuYeuCau.join(', ')}`
                        });
                    }
                });
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán DV Nội soi có sinh thiết (Nội soi thực quản dạ dày tá tràng, nội soi ổ bụng,...) nhưng không làm xét nghiệm giải phẫu mô bệnh học, điều chỉnh về mức giá của các DV nội soi không sinh thiết: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán DV Nội soi có sinh thiết (Nội soi thực quản dạ dày tá tràng, nội soi ổ bụng,...) nhưng không làm xét nghiệm giải phẫu mô bệnh học, điều chỉnh về mức giá của các DV nội soi không sinh thiết';
    }

    return result;
};

module.exports = validateRule_Id_8;