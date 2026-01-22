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
        // Danh sách mã dịch vụ thở máy (đã loại bỏ trùng lặp)
        const dsMaDichVuThoMay = [
            '01.0128.0209', // Thông khí nhân tạo không xâm nhập
            '01.0131.0209', // Thông khí nhân tạo không xâm nhập phương thức BiPAP
            '01.0130.0209', // Thông khí nhân tạo không xâm nhập phương thức CPAP
            '01.0132.0209', // Thông khí nhân tạo xâm nhập
            '01.0135.0209', // Thông khí nhân tạo xâm nhập phương thức A/C (VCV)
            '01.0139.0209', // Thông khí nhân tạo xâm nhập phương thức APRV
            '01.0138.0209', // Thông khí nhân tạo xâm nhập phương thức CPAP
            '01.0141.0209', // Thông khí nhân tạo xâm nhập phương thức HFO
            '01.0140.0209', // Thông khí nhân tạo xâm nhập phương thức NAVA
            '01.0134.0209', // Thông khí nhân tạo xâm nhập phương thức PCV
            '01.0137.0209', // Thông khí nhân tạo xâm nhập phương thức PSV
            '01.0136.0209', // Thông khí nhân tạo xâm nhập phương thức SIMV
            '01.0133.0209', // Thông khí nhân tạo xâm nhập phương thức VCV
            '01.0153.0297', // Thở máy xâm nhập hai phổi độc lập
            '03.0083.0209', // Hỗ trợ hô hấp xâm nhập qua nội khí quản
            '03.0058.0209', // Thở máy bằng xâm nhập
            '03.0082.0209', // Thở máy không xâm nhập (thở CPAP, thở BiPAP)
            '13.0187.0209'  // Hô hấp áp lực dương liên tục (CPAP) không xâm nhập ở trẻ sơ sinh
        ];

        // Lấy dữ liệu dịch vụ và thuốc
        const xml3_data = patientData.Xml3 || [];
        const xml2_data = patientData.Xml2 || [];

        // Duyệt qua từng thuốc Oxy (mã 40.17) từ XML2
        xml2_data.forEach(thuoc => {
            if (thuoc.Ma_Thuoc === '40.17') {
                // Lấy khoảng thời gian của thuốc Oxy: từ Ngay_Yl đến Ngay_Kq
                const oxyTuNgay = thuoc.Ngay_Yl ? parseDateFromString(thuoc.Ngay_Yl) : null;
                const oxyDenNgay = thuoc.Ngay_Kq ? parseDateFromString(thuoc.Ngay_Kq) : null;

                // Nếu không có Ngay_Yl thì bỏ qua
                if (!oxyTuNgay) return;

                // Nếu không có Ngay_Kq, coi như chỉ có một thời điểm (Ngay_Yl)
                const oxyDenNgayFinal = oxyDenNgay || oxyTuNgay;

                // Kiểm tra các dịch vụ thở máy trong XML3
                xml3_data.forEach(dv => {
                    if (dsMaDichVuThoMay.includes(dv.Ma_Dich_Vu)) {
                        // Lấy khoảng thời gian của dịch vụ thở máy: từ Ngay_Th_Yl đến Ngay_Kq
                        const dvTuNgay = (dv.Ngay_Th_Yl || dv.Ngay_th_yl) ? parseDateFromString(dv.Ngay_Th_Yl || dv.Ngay_th_yl) : null;
                        const dvDenNgay = dv.Ngay_Kq ? parseDateFromString(dv.Ngay_Kq) : null;

                        // Nếu thiếu một trong hai ngày thì bỏ qua
                        if (!dvTuNgay || !dvDenNgay) return;

                        // Kiểm tra nếu khoảng thời gian của Oxy NẰM TRONG khoảng thời gian của dịch vụ thở máy
                        // Oxy nằm trong dịch vụ thở máy khi: oxyTuNgay >= dvTuNgay && oxyDenNgayFinal <= dvDenNgay
                        if (oxyTuNgay >= dvTuNgay && oxyDenNgayFinal <= dvDenNgay) {
                            result.isValid = false;
                            result.errors.push({
                                Id: thuoc.id || thuoc.Id,
                                Error: `Không được thanh toán Oxy (mã thuốc 40.17) trong khoảng thời gian từ ${thuoc.Ngay_Yl} đến ${thuoc.Ngay_Kq || thuoc.Ngay_Yl} khi đã thanh toán dịch vụ thở máy (${dv.Ma_Dich_Vu}) từ ${dv.Ngay_Th_Yl} đến ${dv.Ngay_Kq}`
                            });
                            result.errors.push({
                                Id: dv.id || dv.Id,
                                Error: `Không được thanh toán Oxy (mã thuốc 40.17) trong khoảng thời gian từ ${thuoc.Ngay_Yl} đến ${thuoc.Ngay_Kq || thuoc.Ngay_Yl} khi đã thanh toán dịch vụ thở máy (${dv.Ma_Dich_Vu}) từ ${dv.Ngay_Th_Yl} đến ${dv.Ngay_Kq}`
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