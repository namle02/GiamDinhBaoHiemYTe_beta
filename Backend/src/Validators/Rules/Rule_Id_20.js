/**
 * Rule 20: Thanh toán Oxy khi thanh toán đồng thời với dịch vụ thở máy do đã kết cấu chi phí Oxy trong giá dịch vụ, không đúng điểm c khoản 2 Điều 3 Thông tư số 22/2023/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_20 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán Oxy khi thanh toán đồng thời với dịch vụ thở máy do đã kết cấu chi phí Oxy trong giá dịch vụ, không đúng điểm c khoản 2 Điều 3 Thông tư số 22/2023/TT-BYT',
        ruleId: 'Rule_Id_20',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    // Hàm chuyển đổi chuỗi ngày dạng 202403080856 thành đối tượng Date
    function parseDateFromString(str) {
        if (!str || typeof str !== 'string' || str.length < 8) return null;
        // Lấy năm, tháng, ngày, giờ, phút (nếu có)
        const year = parseInt(str.substring(0, 4), 10);
        const month = parseInt(str.substring(4, 6), 10) - 1; // Tháng bắt đầu từ 0
        const day = parseInt(str.substring(6, 8), 10);
        const hour = str.length >= 10 ? parseInt(str.substring(8, 10), 10) : 0;
        const minute = str.length >= 12 ? parseInt(str.substring(10, 12), 10) : 0;
        return new Date(year, month, day, hour, minute);
    }

    try {
        // Danh sách mã dịch vụ thở máy
        const dsMaDichVuThoMay = [
            '01.0136.0209',
            '01.0128.0209',
            '01.0131.0209',
            '01.0134.0209',
            '01.0137.0209',
            '01.0138.0209',
            '01.0137.0209',
            '01.0128.0209',
            '01.0130.0209',
            '01.0135.0209',
            '01.0135.0209',
            '01.0132.0209',
            '01.0133.0209',
            '01.0130.0209',
            '01.0144.0209',
            '01.0134.0209',
            '01.0133.0209'
        ];

        // Lấy dữ liệu dịch vụ và thuốc
        const xml3_data = patientData.Xml3 || [];
        const xml2_data = patientData.Xml2 || [];

        // Duyệt qua từng dịch vụ thở máy
        xml3_data.forEach(dv => {
            if (dsMaDichVuThoMay.includes(dv.Ma_Dich_Vu)) {
                // Lấy ngày y lệnh và ngày kết quả (dạng 202403080856)
                const tuNgay = dv.Ngay_Th_Yl ? parseDateFromString(dv.Ngay_Th_Yl) : null;
                const denNgay = dv.Ngay_Kq ? parseDateFromString(dv.Ngay_Kq) : null;

                if (!tuNgay || !denNgay) return; // Nếu thiếu ngày thì bỏ qua

                // Kiểm tra trong khoảng thời gian này có thuốc Oxy không
                xml2_data.forEach(thuoc => {
                    if (thuoc.Ma_Thuoc === '40.17') {
                        // Lấy ngày cấp thuốc (dạng 202403080856)
                        const ngayYLenhThuoc = thuoc.Ngay_Yl ? parseDateFromString(thuoc.Ngay_Yl) : null;
                        if (!ngayYLenhThuoc) return;

                        // Nếu ngày cấp thuốc nằm trong khoảng từ ngày y lệnh đến ngày kết quả của dịch vụ thở máy
                        if (ngayYLenhThuoc >= tuNgay && ngayYLenhThuoc <= denNgay) {
                            result.isValid = false;
                            result.errors.push({
                                Id: dv.Id,
                                Error: `Không được thanh toán đồng thời Oxy (mã thuốc 40.17) với dịch vụ thở máy (${dv.Ma_Dich_Vu}) trong cùng khoảng thời gian từ ngày y lệnh đến ngày kết quả`
                            });
                            result.errors.push({
                                Id: thuoc.Id,
                                Error: `Không được thanh toán đồng thời Oxy (mã thuốc 40.17) với dịch vụ thở máy (${dv.Ma_Dich_Vu}) trong cùng khoảng thời gian từ ngày y lệnh đến ngày kết quả`
                            });
                        }
                    }
                });
            }
        });

        if (result.errors.length > 0) {
            result.isValid = false;
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán Oxy khi thanh toán đồng thời với dịch vụ thở máy do đã kết cấu chi phí Oxy trong giá dịch vụ, không đúng điểm c khoản 2 Điều 3 Thông tư số 22/2023/TT-BYT: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán Oxy khi thanh toán đồng thời với dịch vụ thở máy do đã kết cấu chi phí Oxy trong giá dịch vụ, không đúng điểm c khoản 2 Điều 3 Thông tư số 22/2023/TT-BYT';
    }

    return result;
};

module.exports = validateRule_Id_20;