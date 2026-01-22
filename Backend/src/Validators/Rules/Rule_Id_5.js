/**
 * Rule 5: HBA1C sai: Khoảng cách giữa 2 lần XN HbA1c tối thiểu là 87 ngày, và bắt buộc có mã ICD từ E10-E14 hoặc O24
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_5 = async (patientData) => {
    const result = {
        ruleName: 'HBA1C Thanh toán dịch vụ HbA1C không đúng chỉ định theo quy định tại Thông tư số 13/2020/TT-BYT sửa đổi, bổ sung một số điều của Thông tư số 35/2016/TT-BYT',
        ruleId: 'Rule_Id_5',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;
        for (const item of xml3_data) {
            const Ma_Dich_Vu = item.Ma_Dich_Vu;
            const Ma_Benh = item.Ma_Benh;
            const Ngay_Yl = item.Ngay_Yl;
            const Ngay_Kq = item.Ngay_Kq;
            const Khoang_Cach = Ngay_Kq - Ngay_Yl;

            if (Ma_Dich_Vu === '23.0083.1523') {
                if (Khoang_Cach < 87) {
                    result.isValid = false;
                    result.errors.push({ Id: item.id || item.Id, Error: 'Khoảng cách giữa 2 lần XN HbA1c tối thiểu là 87 ngày' });
                }
                else if (!Ma_Benh.includes('E10') && !Ma_Benh.includes('E11') && !Ma_Benh.includes('E12') && !Ma_Benh.includes('E13') && !Ma_Benh.includes('E14') && !Ma_Benh.includes('O24')) {
                    result.isValid = false;
                    result.errors.push({ Id: item.id || item.Id, Error: 'Mã ICD không hợp lệ' });
                }
            }

        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate HBA1C sai: ${error.message}`);
        result.message = 'Lỗi khi validate HBA1C sai';
    }

    return result;
};

module.exports = validateRule_Id_5;