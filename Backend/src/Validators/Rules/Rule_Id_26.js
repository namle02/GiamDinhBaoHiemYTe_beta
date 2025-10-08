/**
 * Rule 26: Thanh toán thuốc chứa hoạt chất Peptid không đúng quy định tại Thông tư số 20/2022/TT-BYT ((Cerebrolysin, Citicolin, Choline alfoscerat) chỉ định sử dụng đối với người bệnh không mắc các bệnh: bệnh đột quỵ cấp tính; Sau chấn thương và phẫuthuật chấn thương sọ não; Sau phẫu thuật thần kinh sọ não)
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_26 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán thuốc chứa hoạt chất Peptid không đúng quy định tại Thông tư số 20/2022/TT-BYT ((Cerebrolysin, Citicolin, Choline alfoscerat) chỉ định sử dụng đối với người bệnh không mắc các bệnh: bệnh đột quỵ cấp tính; Sau chấn thương và phẫu thuật chấn thương sọ não; Sau phẫu thuật thần kinh sọ não)',
        ruleId: 'Rule_Id_26',
        isValid: true,
        validateField: 'Ma_Thuoc',
        validateFile:'XML2',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml2_data = patientData.Xml2 || [];
        // Lấy danh sách mã dịch vụ
        const danhsachthuoc = xml2_data.map(item => item.Ma_Thuoc);

        // Nếu có mã dịch vụ 40.563 thì kiểm tra mã bệnh
        if (danhsachthuoc.includes('40.563')) {
            // Lấy tất cả mã bệnh của các dịch vụ có mã 40.563
            const maBenhLienQuan = xml2_data
                .filter(item => item.Ma_Thuoc === '40.563')
                .map(item => item.Ma_Benh)
                .filter(Boolean);

            // Danh sách mã bệnh hợp lệ
            const maBenhHopLe = ['I63', 'I64', 'S06', 'Z48'];

            // Kiểm tra xem có ít nhất một mã bệnh hợp lệ không
            // Mỗi mã bệnh là một chuỗi dạng "I10;H81.8;I87.2;E78.2"
            const coMaBenhHopLe = maBenhLienQuan.some(maBenhStr => {
                // Tách chuỗi thành mảng các mã bệnh riêng lẻ
                const arrMaBenh = maBenhStr.split(';').map(s => s.trim().toUpperCase()).filter(Boolean);
                // Kiểm tra xem có mã nào thuộc danh sách hợp lệ không
                return arrMaBenh.some(ma => maBenhHopLe.some(code => ma.startsWith(code)));
            });

            if (!coMaBenhHopLe) {
                result.isValid = false;
                xml2_data.filter(it => it.Ma_Thuoc === '40.563').forEach(it => {
                    result.errors.push({ Id: it.Id, Error: 'Thuốc nhóm Peptid (40.563) không có mã bệnh hợp lệ (I63, I64, S06, Z48)' });
                });
                result.message = 'Không hợp lệ thuốc nhóm Peptid do thiếu mã bệnh phù hợp';
            }
        }   
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán thuốc chứa hoạt chất Peptid không đúng quy định tại Thông tư số 20/2022/TT-BYT ((Cerebrolysin, Citicolin, Choline alfoscerat) chỉ định sử dụng đối với người bệnh không mắc các bệnh: bệnh đột quỵ cấp tính; Sau chấn thương và phẫu thuật chấn thương sọ não; Sau phẫu thuật thần kinh sọ não): ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán thuốc chứa hoạt chất Peptid không đúng quy định tại Thông tư số 20/2022/TT-BYT ((Cerebrolysin, Citicolin, Choline alfoscerat) chỉ định sử dụng đối với người bệnh không mắc các bệnh: bệnh đột quỵ cấp tính; Sau chấn thương và phẫu thuật chấn thương sọ não; Sau phẫu thuật thần kinh sọ não)';
    }

    return result;
};

module.exports = validateRule_Id_26;