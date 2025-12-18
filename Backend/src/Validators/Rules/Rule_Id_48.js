/**
 * Rule 48: Các dịch vụ châm, cứu thanh toán theo phương pháp, không thanh toán theo vị trí, vùng cơ thể
 * Chỉ được thanh toán 1 lần/ngày
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_48 = async (patientData) => {
    const result = {
        ruleName: 'Các dịch vụ châm, cứu thanh toán theo phương pháp, không thanh toán theo vị trí, vùng cơ thể',
        ruleId: 'Rule_Id_48',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile: 'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];

        if (!Array.isArray(xml3_data)) {
            throw new Error('Dữ liệu XML3 không hợp lệ hoặc thiếu');
        }

        // Danh sách các cụm từ cần tìm trong tên dịch vụ (không phân biệt hoa thường)
        const cumTuCanTim = [
            'điện châm',
            'điện mãng châm',
            'điện nhĩ câm',
            'thủy câm',
            'cứu'
        ];

        // Hàm kiểm tra tên dịch vụ có chứa các cụm từ cần tìm
        const kiemTraTenDichVu = (tenDichVu) => {
            if (!tenDichVu || typeof tenDichVu !== 'string') {
                return false;
            }
            const tenDichVuLower = tenDichVu.toLowerCase().trim();
            return cumTuCanTim.some(cumTu => tenDichVuLower.includes(cumTu.toLowerCase()));
        };

        // Lọc các dịch vụ thỏa mãn điều kiện:
        // 1. Mã dịch vụ bắt đầu bằng "08."
        // 2. Tên dịch vụ chứa một trong các cụm từ: điện châm, điện mãng châm, điện nhĩ câm, thủy câm, cứu
        const dichVuChamCuu = xml3_data.filter(item => {
            const maDichVu = item.Ma_Dich_Vu || '';
            const tenDichVu = item.Ten_Dich_Vu || '';
            
            // Kiểm tra mã dịch vụ bắt đầu bằng "08."
            const maHopLe = maDichVu.startsWith('08.');
            
            // Kiểm tra tên dịch vụ
            const tenHopLe = kiemTraTenDichVu(tenDichVu);
            
            return maHopLe && tenHopLe;
        });

        // Nhóm các dịch vụ theo ngày (sử dụng Ngay_Th_Yl - ngày thực hiện y lệnh)
        // Nếu không có Ngay_Th_Yl thì dùng Ngay_Yl
        const nhomTheoNgay = {};
        
        dichVuChamCuu.forEach(item => {
            // Lấy ngày từ Ngay_Th_Yl hoặc Ngay_Yl
            let ngayStr = item.Ngay_Th_Yl || item.Ngay_Yl || '';
            
            // Chuyển đổi ngày về định dạng yyyyMMdd (lấy 8 ký tự đầu nếu có)
            if (ngayStr) {
                ngayStr = ngayStr.toString().trim();
                // Nếu có định dạng yyyyMMddHHmmss thì chỉ lấy 8 ký tự đầu
                if (ngayStr.length >= 8) {
                    ngayStr = ngayStr.substring(0, 8);
                } else if (ngayStr.includes('-')) {
                    // Nếu có định dạng yyyy-MM-dd thì chuyển về yyyyMMdd
                    ngayStr = ngayStr.replace(/-/g, '').substring(0, 8);
                }
            }
            
            if (!ngayStr || ngayStr.length < 8) {
                // Nếu không có ngày hợp lệ, bỏ qua
                return;
            }
            
            if (!nhomTheoNgay[ngayStr]) {
                nhomTheoNgay[ngayStr] = [];
            }
            nhomTheoNgay[ngayStr].push(item);
        });

        // Kiểm tra các ngày có nhiều hơn 1 dịch vụ
        Object.keys(nhomTheoNgay).forEach(ngay => {
            const dsDichVu = nhomTheoNgay[ngay];
            
            if (dsDichVu.length > 1) {
                // Có nhiều hơn 1 dịch vụ trong cùng 1 ngày -> vi phạm
                result.isValid = false;
                
                // Tạo danh sách mã dịch vụ và tên dịch vụ để hiển thị trong lỗi
                const danhSachMaDichVu = dsDichVu.map(item => item.Ma_Dich_Vu).join(', ');
                const danhSachTenDichVu = dsDichVu.map(item => item.Ten_Dich_Vu || 'N/A').join(', ');
                
                // Báo lỗi cho tất cả các dịch vụ trong ngày đó
                dsDichVu.forEach(item => {
                    result.errors.push({
                        Id: item.Id,
                        Error: `Các dịch vụ châm, cứu chỉ được thanh toán 1 lần/ngày. Ngày ${ngay} có ${dsDichVu.length} dịch vụ: ${danhSachMaDichVu}. Tên dịch vụ: ${danhSachTenDichVu}`
                    });
                });
            }
        });

        if (result.errors.length > 0) {
            result.message = 'Có dịch vụ châm, cứu được thanh toán nhiều hơn 1 lần trong cùng 1 ngày';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(
            `Lỗi khi validate Các dịch vụ châm, cứu thanh toán theo phương pháp, không thanh toán theo vị trí, vùng cơ thể: ${error.message}`
        );
        result.message = 'Lỗi khi validate Các dịch vụ châm, cứu thanh toán theo phương pháp, không thanh toán theo vị trí, vùng cơ thể';
    }

    return result;
};

module.exports = validateRule_Id_48;

