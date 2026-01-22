/**
 * Rule 43: Thanh toán băng gạc không đúng quy định
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const ds_dichvu = [
    "N02.03.090.2794.240.0004",
    "N02.03.090.2794.240.0005",
    "N02.03.090.2794.240.0003",
    "N02.03.090.2794.240.0007",
    "N02.03.080.2794.240.0010",
    "N02.03.040.2794.240.0014",
    "N02.03.040.2794.240.0012"
]

const ds_dichvu_banggac = [
    "07.0225.0200",
    "07.0225.0201",
    "07.0225.0202",
    "07.0225.0203",
    "07.0225.0204",
    "07.0225.0205"
]

const validateRule_Id_43 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán băng gạc không đúng quy định',
        ruleId: 'Rule_Id_1',
        isValid: true,
        validateField: 'Ma_Vat_Tu',
        validateFile: 'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        
        // Hàm lấy phần ngày từ Ngay_Yl (dạng yyyyMMddHHmm - 14 ký tự)
        // Trả về yyyyMMdd (8 ký tự đầu)
        function getNgayFromNgayYl(ngayYl) {
            if (!ngayYl) return null;
            const ngayStr = String(ngayYl).trim();
            // Lấy 8 ký tự đầu (yyyyMMdd)
            return ngayStr.length >= 8 ? ngayStr.substring(0, 8) : ngayStr;
        }

        // Lọc các VTYT có Ma_Vat_Tu trong ds_dichvu (các vật tư không được thanh toán nếu không có dịch vụ kỹ thuật)
        const dsVTYT = xml3_data.filter(item => 
            item.Ma_Vat_Tu && ds_dichvu.includes(item.Ma_Vat_Tu)
        );
        
        // Lọc các dịch vụ kỹ thuật có Ma_Dich_Vu trong ds_dichvu_banggac
        const dsDichVuBangGac = xml3_data.filter(item => 
            item.Ma_Dich_Vu && ds_dichvu_banggac.includes(item.Ma_Dich_Vu)
        );

        // Tạo map các ngày có dịch vụ kỹ thuật thay băng (để tra cứu nhanh)
        const ngayCoDichVuBangGac = new Set();
        dsDichVuBangGac.forEach(item => {
            const ngay = getNgayFromNgayYl(item.Ngay_Yl);
            if (ngay) {
                ngayCoDichVuBangGac.add(ngay);
            }
        });

        // Kiểm tra từng VTYT: nếu KHÔNG CÓ dịch vụ kỹ thuật thay băng trong cùng ngày → LỖI
        dsVTYT.forEach(item => {
            const ngayYl = getNgayFromNgayYl(item.Ngay_Yl);
            
            if (!ngayYl) {
                return;
            }
            
            // Kiểm tra xem trong cùng ngày có dịch vụ kỹ thuật thay băng không
            if (!ngayCoDichVuBangGac.has(ngayYl)) {
                result.isValid = false;
                result.errors.push({
                    Id: item.id || item.Id,
                    Error: `VTYT ${item.Ma_Vat_Tu} không được thanh toán vì không có dịch vụ kỹ thuật thay băng trong cùng ngày ${ngayYl}`
                });
            }
        })
       
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán băng gạc không đúng quy định: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán băng gạc không đúng quy định';
    }
    return result;
}

module.exports = validateRule_Id_43;