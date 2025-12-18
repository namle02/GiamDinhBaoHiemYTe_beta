/**
 * Rule 15:Thanh toán dịch vụ kỹ thuật tiêm bắp, tiêm tĩnh mạch, truyền tĩnh mạch, tháo bột các loại, cắt chỉ… trong điều trị ngoại trú, không thanh toán trong điều trị nội trú.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_15 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ kỹ thuật tiêm bắp, tiêm tĩnh mạch, truyền tĩnh mạch, tháo bột các loại, cắt chỉ… trong điều trị ngoại trú, không thanh toán trong điều trị nội trú.',
        ruleId: 'Rule_Id_15',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        const xml1 = Array.isArray(patientData.Xml1) && patientData.Xml1.length > 0 ? patientData.Xml1[0] : {};

        // Danh sách mã dịch vụ cần kiểm tra
        const danhSachMaDichVuCanKiemTra = [
           '01.0006.0215', // Đặt catheter tĩnh mạch ngoại biên
            '03.1703.0075', // Cắt chỉ khâu da
            '03.1681.0075', // Cắt chỉ khâu giác mạc
            '03.1690.0075', // Cắt chỉ khâu kết mạc
            '03.3826.0075', // Thay băng, cắt chỉ vết mổ
            '03.4246.0198', // Tháo bột các loại
            '03.2389.0212', // Tiêm bắp thịt
            '03.2388.0212', // Tiêm dưới da
            '03.2390.0212', // Tiêm tĩnh mạch
            '03.2387.0212', // Tiêm trong da
            '03.2391.0215', // Truyền tĩnh mạch
            '03.2793.1169', // Truyền hóa chất tĩnh mạch
            '10.9004.0075_BS', // Cắt chỉ
            '11.0089.0215', // Đặt dây truyền dịch ngoại vi điều trị người bệnh bỏng
            '12.0368.1169', // Truyền hóa chất tĩnh mạch
            '14.0203.0075', // Cắt chỉ khâu da mi đơn giản
            '14.0192.0075', // Cắt chỉ khâu giác mạc
            '14.0204.0075', // Cắt chỉ khâu kết mạc
            '14.0111.0075', // Cắt chỉ sau phẫu thuật lác
            '14.0116.0075', // Cắt chỉ sau phẫu thuật lác, sụp mi
            '14.0112.0075', // Cắt chỉ sau phẫu thuật sụp mi
            '14.0291.0212', // Tiêm tĩnh mạch, truyền tĩnh mạch
            '14.0290.0212', // Tiêm trong da; tiêm dưới da; tiêm bắp thịt
            '15.0302.0075', // Cắt chỉ sau phẫu thuật
            
        ];

        // Lấy Ma_Loai_Kcb từ xml1 (có thể là string hoặc number)
        const maLoaiKcb = xml1.Ma_Loai_Kcb;
        const maLoaiKcbStr = maLoaiKcb !== null && maLoaiKcb !== undefined ? String(maLoaiKcb).trim() : '';

        // Kiểm tra nếu Ma_Loai_Kcb là 1 hoặc 2
        if (maLoaiKcbStr === '1' || maLoaiKcbStr === '2') {
            // Tìm các dịch vụ trong xml3_data có mã trong danh sách cần kiểm tra
            xml3_data.forEach(item => {
                if (item.Ma_Dich_Vu && danhSachMaDichVuCanKiemTra.includes(item.Ma_Dich_Vu)) {
                    result.isValid = false;
                    result.errors.push({
                        Id: item.Id,
                        Error: `Dịch vụ ${item.Ma_Dich_Vu} không được thanh toán khi Ma_Loai_KCB là ${maLoaiKcbStr}`
                    });
                }
            });
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ kỹ thuật tiêm bắp, tiêm tĩnh mạch, truyền tĩnh mạch, tháo bột các loại, cắt chỉ… trong điều trị ngoại trú, không thanh toán trong điều trị nội trú.: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ kỹ thuật tiêm bắp, tiêm tĩnh mạch, truyền tĩnh mạch, tháo bột các loại, cắt chỉ… trong điều trị ngoại trú, không thanh toán trong điều trị nội trú.';
    }

    return result;
};

module.exports = validateRule_Id_15;