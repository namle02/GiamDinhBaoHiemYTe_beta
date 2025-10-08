/**
 * Rule 22: Thanh toán tiền khám bệnh đối với người bệnh khám bệnh và vào điều trị nội trú tại khoa cấp cứu, không đúng quy định tại khoản 1 Điều 5 Thông tư số 22/2023/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_22 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán tiền khám bệnh đối với người bệnh khám bệnh và vào điều trị nội trú tại khoa cấp cứu, không đúng quy định tại khoản 1 Điều 5 Thông tư số 22/2023/TT-BYT',
        ruleId: 'Rule_Id_22',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];

        // Danh sách mã dịch vụ giường
        const danhsachdichvugiuong = [
            'K48.1905',
            'K48.1902'
        ];

        // Danh sách mã dịch vụ khám bệnh
        const danhsachdichvukhambenh = [
            '02.1896',
            '10.1896'
        ];

        // Lấy danh sách mã dịch vụ thực tế
        const danhsachdichvu = xml3_data.map(item => item.Ma_Dich_Vu);

        // Kiểm tra nếu có ít nhất 1 dịch vụ giường và ít nhất 1 dịch vụ khám bệnh thì báo lỗi
        const coDichVuGiuong = danhsachdichvu.some(ma => danhsachdichvugiuong.includes(ma));
        const coDichVuKhamBenh = danhsachdichvu.some(ma => danhsachdichvukhambenh.includes(ma));

        if (coDichVuGiuong && coDichVuKhamBenh) {
            result.isValid = false;
            xml3_data.forEach(item => {
                if (danhsachdichvugiuong.includes(item.Ma_Dich_Vu) || danhsachdichvukhambenh.includes(item.Ma_Dich_Vu)) {
                    result.errors.push({ Id: item.Id, Error: 'Không thanh toán đồng thời dịch vụ giường và khám bệnh (TT 22/2023/TT-BYT)' });
                }
            });
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán tiền khám bệnh đối với người bệnh khám bệnh và vào điều trị nội trú tại khoa cấp cứu, không đúng quy định tại khoản 1 Điều 5 Thông tư số 22/2023/TT-BYT: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán tiền khám bệnh đối với người bệnh khám bệnh và vào điều trị nội trú tại khoa cấp cứu, không đúng quy định tại khoản 1 Điều 5 Thông tư số 22/2023/TT-BYT';
    }

    return result;
};

module.exports = validateRule_Id_22;