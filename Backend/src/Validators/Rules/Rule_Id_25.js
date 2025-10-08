/**
 * Rule 25: Thanh toán giường điều trị nội trú ban ngày tại cơ sở khám bệnh chữa bệnh YHCT không đúng quy định tại Thông tư số 01/2019/TT-BYT ngày 01/3/2019 của Bộ trưởng Bộ Y tế quy định việc thực hiện điều trị nội trú ban ngày tại cơ sở khám bệnh, chữa bệnh y học cổ truyền và Công văn số 4712/BYT-YDCT ngày 15/ 8/ 2019 hướng dẫn thực hiện Thông tư số 01/2019/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_25 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán giường điều trị nội trú ban ngày tại cơ sở khám bệnh chữa bệnh YHCT không đúng quy định tại Thông tư số 01/2019/TT-BYT ngày 01/3/2019 của Bộ trưởng Bộ Y tế quy định việc thực hiện điều trị nội trú ban ngày tại cơ sở khám bệnh, chữa bệnh y học cổ truyền và Công văn số 4712/BYT-YDCT ngày 15/ 8/ 2019 hướng dẫn thực hiện Thông tư số 01/2019/TT-BYT',
        ruleId: 'Rule_Id_25',
        isValid: true,
        validateField: 'Ma_Khoa',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        // Danh sách mã khoa/phòng ban YHCT hợp lệ
        const danhsachphongbanyhct = [
            'PKDY',
            'D15',
            'D15YC',
            'D15_NT',
        ];

        xml3_data.forEach(item => {
            // Kiểm tra nếu tên dịch vụ có chứa "ngày giường ban ngày nội khoa" (không phân biệt hoa thường)
            if (
                item.Ten_Dich_Vu &&
                item.Ten_Dich_Vu.toLowerCase().includes('ngày giường ban ngày nội khoa')
            ) {
                // Nếu mã khoa không nằm trong danh sách phòng ban YHCT thì báo lỗi
                if (!danhsachphongbanyhct.includes(item.Ma_Khoa)) {
                    result.isValid = false;
                    result.errors.push({ Id: item.Id, Error: `Mã khoa "${item.Ma_Khoa}" không thuộc danh sách phòng ban YHCT hợp lệ cho dịch vụ ngày giường ban ngày nội khoa` });
                }
            }
        });

        if (result.errors.length > 0) {
            result.message = 'Có dịch vụ ngày giường ban ngày nội khoa nhưng mã khoa không thuộc danh sách phòng ban YHCT hợp lệ.';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán giường điều trị nội trú ban ngày tại cơ sở khám bệnh chữa bệnh YHCT không đúng quy định tại Thông tư số 01/2019/TT-BYT ngày 01/3/2019 của Bộ trưởng Bộ Y tế quy định việc thực hiện điều trị nội trú ban ngày tại cơ sở khám bệnh, chữa bệnh y học cổ truyền và Công văn số 4712/BYT-YDCT ngày 15/ 8/ 2019 hướng dẫn thực hiện Thông tư số 01/2019/TT-BYT: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán giường điều trị nội trú ban ngày tại cơ sở khám bệnh chữa bệnh YHCT không đúng quy định tại Thông tư số 01/2019/TT-BYT ngày 01/3/2019 của Bộ trưởng Bộ Y tế quy định việc thực hiện điều trị nội trú ban ngày tại cơ sở khám bệnh, chữa bệnh y học cổ truyền và Công văn số 4712/BYT-YDCT ngày 15/ 8/ 2019 hướng dẫn thực hiện Thông tư số 01/2019/TT-BYT';
    }

    return result;
};

module.exports = validateRule_Id_25;