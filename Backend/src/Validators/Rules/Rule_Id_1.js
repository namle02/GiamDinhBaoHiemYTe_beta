/**
 * Rule 1: Thanh toán dịch vụ Vi khuẩn nuôi cấy định danh, không thanh toán thêm DVKT Vi khuẩn nhuộm soi
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_1 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ Vi khuẩn nuôi cấy định danh, không thanh toán thêm DVKT Vi khuẩn nhuộm soi',
        ruleId: 'Rule_Id_1',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách dịch vụ từ Xml3
        const dsDichVu = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];

        // Các mã dịch vụ cần kiểm tra
        const maDV1 = '24.0001.1714';
        const maDV2 = '24.0005.1716';
        const maDV3 = '24.0003.1715';

        // Tạo map: LoaiBenhPham_Id => danh sách dịch vụ thuộc loại đó
        // Mỗi phần tử là object { Ma_Dich_Vu, Id }
        const mapLoaiBenhPham = {};

        dsDichVu.forEach(dv => {
            const lbp = dv.LoaiBenhPham_Id;
            const maDV = dv.Ma_Dich_Vu;
            if (!lbp || !maDV) return;
            if (!mapLoaiBenhPham[lbp]) mapLoaiBenhPham[lbp] = [];
            mapLoaiBenhPham[lbp].push({ Ma_Dich_Vu: maDV, Id: dv.Id });
        });

        // Kiểm tra từng loại bệnh phẩm xem có đồng thời các mã dịch vụ không hợp lệ không
        Object.entries(mapLoaiBenhPham).forEach(([lbp, dsDV]) => {
            // Lấy danh sách mã dịch vụ
            const dsMaDV = dsDV.map(dv => dv.Ma_Dich_Vu);
            if (
                dsMaDV.includes(maDV1) &&
                (dsMaDV.includes(maDV2) || dsMaDV.includes(maDV3))
            ) {
                // Nếu có cả 24.0001.1714 và (24.0005.1716 hoặc 24.0003.1715) cùng loại bệnh phẩm thì báo lỗi
                // Lấy ra Id của các dịch vụ bị lỗi
                dsDV.forEach(dv => {
                    if (
                        dv.Ma_Dich_Vu === maDV1 ||
                        dv.Ma_Dich_Vu === maDV2 ||
                        dv.Ma_Dich_Vu === maDV3
                    ) {
                        result.errors.push({
                            Id: dv.Id,
                            Error: `Không được đồng thời thanh toán các dịch vụ 24.0001.1714 và (24.0005.1716 hoặc 24.0003.1715) cho cùng một loại bệnh phẩm`
                        });
                    }
                });
                result.isValid = false;
            }
        });

        if (result.errors.length > 0) {
            result.isValid = false;
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ Vi khuẩn nuôi cấy định danh, không thanh toán thêm DVKT Vi khuẩn nhuộm soi: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ Vi khuẩn nuôi cấy định danh, không thanh toán thêm DVKT Vi khuẩn nhuộm soi';
    }

    return result;
};

module.exports = validateRule_Id_1;