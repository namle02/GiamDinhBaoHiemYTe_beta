/**
 * Rule 13: Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trong cơ cấu giá kỹ thuật chạy thận nhân tạo.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_13 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trong cơ cấu giá kỹ thuật chạy thận nhân tạo.',
        ruleId: 'Rule_Id_13',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        const xml2_data = Array.isArray(patientData.Xml2) ? patientData.Xml2 : [];

        // Danh sách mã dịch vụ thận nhân tạo
        const danhSachMaDichVuThanNhanTao = [
            '01.0174.0195', // Thận nhân tạo cấp cứu
            '01.0175.0196', // Thận nhân tạo thường quy
            '02.0496.0195', // Thận nhân tạo cấp cứu (quả lọc, dây máu 1 lần)
            '02.0495.0196', // Thận nhân tạo chu kỳ (quả lọc, dây máu 6 lần)
            '02.0226.2038', // Phối hợp thận nhân tạo (HD) và hấp thụ máu (HP) bằng quả hấp phụ máu
            '03.0011.0196'  // Thận nhân tạo (ở người đã có mở thông động tĩnh mạch)
        ];

        // Danh sách mã thuốc chống đông (MA_CP)
        const danhSachMaThuocChongDong = ['40.443', '40.445'];

        // Hàm lấy phần ngày từ Ngay_Yl (dạng yyyyMMddHHmm - 14 ký tự)
        // Trả về yyyyMMdd (8 ký tự đầu) để so sánh cùng ngày
        function getNgayFromNgayYl(ngayYl) {
            if (!ngayYl) return null;
            const ngayStr = String(ngayYl).trim();
            // Lấy 8 ký tự đầu (yyyyMMdd)
            return ngayStr.length >= 8 ? ngayStr.substring(0, 8) : ngayStr;
        }

        // Tìm các dịch vụ thận nhân tạo
        const dsChayThan = xml3_data.filter(item => 
            danhSachMaDichVuThanNhanTao.includes(item.Ma_Dich_Vu) && item.Ngay_Yl
        );

        // Tìm các thuốc chống đông
        const dsThuocChongDong = xml2_data.filter(item => 
            danhSachMaThuocChongDong.includes(item.Ma_Thuoc) && item.Ngay_Yl
        );

        // Kiểm tra từng dịch vụ thận nhân tạo xem có thuốc chống đông cùng thời điểm không
        dsChayThan.forEach(dichVu => {
            const ngayDichVu = getNgayFromNgayYl(dichVu.Ngay_Yl);
            
            // Tìm các thuốc chống đông cùng ngày
            const thuocCungNgay = dsThuocChongDong.filter(thuoc => {
                const ngayThuoc = getNgayFromNgayYl(thuoc.Ngay_Yl);
                return ngayThuoc === ngayDichVu;
            });

            if (thuocCungNgay.length > 0) {
                result.isValid = false;
                // Báo lỗi cho dịch vụ
                result.errors.push({
                    Id: dichVu.Id,
                    Error: `Không được đồng thời thanh toán dịch vụ thận nhân tạo (${dichVu.Ma_Dich_Vu}) và thuốc chống đông (${thuocCungNgay.map(t => t.Ma_Thuoc).join(', ')}) cùng thời điểm (ngày ${ngayDichVu}) do đã có trong cơ cấu giá kỹ thuật chạy thận nhân tạo.`
                });

                // Báo lỗi cho các thuốc chống đông cùng ngày
                thuocCungNgay.forEach(thuoc => {
                    result.errors.push({
                        Id: thuoc.Id,
                        Error: `Thuốc chống đông (${thuoc.Ma_Thuoc}) không được thanh toán cùng thời điểm với dịch vụ thận nhân tạo (${dichVu.Ma_Dich_Vu}) vào ngày ${ngayDichVu} do đã có trong cơ cấu giá kỹ thuật chạy thận nhân tạo.`
                    });
                });
            }
        });
      
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ chạy thận nhân tạo, không thanh toán thêm thuốc chống đông hoạt chất Enoxaparin (natri) hoặc Heparin (natri) do đã có trongcơ cấu giá kỹ thuật chạy thận nhân tạo.';
    }

    return result;
};

module.exports = validateRule_Id_13;