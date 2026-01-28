/**
 * Rule 40: Azithromycin quá liều và không được sử dụng liên tiếp 5 ngày
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_40 = async (patientData) => {
    const result = {
        ruleName: 'Azithromycin quá liều và không được sử dụng liên tiếp 5 ngày',
        ruleId: 'Rule_Id_40',
        isValid: true,
        validateField: 'Ham_Luong',
        validateFile:'XML2',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách thuốc từ Xml2
        const xml2_data = Array.isArray(patientData.Xml2) ? patientData.Xml2 : [];
        
        // Lọc tất cả thuốc có Ma_Thuoc = "40.219"
        const danhSachAzithromycin = xml2_data.filter(item => 
            item.Ma_Thuoc === '40.219' && item.Ngay_Yl && item.Ham_Luong
        );

        // Nếu không có thuốc Azithromycin thì bỏ qua
        if (danhSachAzithromycin.length === 0) {
            return result;
        }

        // Hàm parse Ham_Luong để lấy số (mg)
        // Định dạng: "250mg", "500mg", "250 mg", v.v.
        function parseHamLuong(hamLuongStr) {
            if (!hamLuongStr) return null;
            // Loại bỏ khoảng trắng và chuyển sang chữ thường
            const cleaned = String(hamLuongStr).trim().toLowerCase();
            
            // Xử lý trường hợp có "g" (gram) - chuyển sang mg
            if (cleaned.includes('g') && !cleaned.includes('mg')) {
                const match = cleaned.match(/(\d+(?:\.\d+)?)\s*g/);
                if (match) {
                    return parseFloat(match[1]) * 1000; // Chuyển gram sang mg
                }
            }
            
            // Tìm số trong chuỗi (ví dụ: "250mg" -> 250)
            const match = cleaned.match(/(\d+(?:\.\d+)?)/);
            if (match) {
                return parseFloat(match[1]);
            }
            return null;
        }

        // Hàm lấy phần ngày từ Ngay_Yl (dạng yyyyMMddHHmm - 14 ký tự)
        // Trả về yyyyMMdd (8 ký tự đầu)
        function getNgayFromNgayYl(ngayYl) {
            if (!ngayYl) return null;
            const ngayStr = String(ngayYl).trim();
            // Lấy 8 ký tự đầu (yyyyMMdd)
            return ngayStr.length >= 8 ? ngayStr.substring(0, 8) : ngayStr;
        }

        // Hàm chuyển đổi yyyyMMdd (hoặc yyyyMMddHHmm, yyyyMMddHHmmss) sang Date object
        // Hỗ trợ: 8 ký tự (yyyyMMdd), 12 ký tự (yyyyMMddHHmm), 14 ký tự (yyyyMMddHHmmss)
        // Chỉ lấy phần ngày để so sánh (bỏ qua giờ/phút)
        function parseDate(ngayStr) {
            if (!ngayStr) return null;
            const str = String(ngayStr).trim();
            if (str.length < 8) return null;
            
            // Lấy 8 ký tự đầu (yyyyMMdd) bất kể input có bao nhiêu ký tự
            const year = parseInt(str.substring(0, 4), 10);
            const month = parseInt(str.substring(4, 6), 10) - 1; // Month is 0-indexed
            const day = parseInt(str.substring(6, 8), 10);
            
            const parsedDate = new Date(year, month, day);
            // Kiểm tra Date hợp lệ
            if (Number.isNaN(parsedDate.getTime())) return null;
            return parsedDate;
        }

        // Hàm tính khoảng cách giữa 2 ngày (số ngày)
        function tinhKhoangCachNgay(ngay1, ngay2) {
            const date1 = parseDate(ngay1);
            const date2 = parseDate(ngay2);
            if (!date1 || !date2) return null;
            const diffTime = Math.abs(date2 - date1);
            return Math.floor(diffTime / (1000 * 60 * 60 * 24));
        }

        // Hàm so sánh Ngay_Yl (so sánh theo ngày yyyyMMdd)
        function compareNgayYl(ngay1, ngay2) {
            const ngay1Str = getNgayFromNgayYl(ngay1);
            const ngay2Str = getNgayFromNgayYl(ngay2);
            return ngay1Str.localeCompare(ngay2Str);
        }

        // Sắp xếp danh sách theo Ngay_Yl (tăng dần)
        danhSachAzithromycin.sort((a, b) => compareNgayYl(a.Ngay_Yl, b.Ngay_Yl));

        // Nhóm các thuốc theo ngày và tính tổng hàm lượng mỗi ngày
        const thuocTheoNgay = {};
        
        danhSachAzithromycin.forEach(item => {
            const ngay = getNgayFromNgayYl(item.Ngay_Yl);
            if (!ngay) return;
            
            if (!thuocTheoNgay[ngay]) {
                thuocTheoNgay[ngay] = [];
            }
            thuocTheoNgay[ngay].push(item);
        });

        // Lấy danh sách các ngày đã sử dụng và sắp xếp
        const cacNgaySuDung = Object.keys(thuocTheoNgay).sort();

        // Lấy ngày đầu tiên (nhỏ nhất)
        const ngayDauTien = cacNgaySuDung.length > 0 ? cacNgaySuDung[0] : null;

        // Kiểm tra tổng hàm lượng trong mỗi ngày
        cacNgaySuDung.forEach(ngay => {
            const thuocTrongNgay = thuocTheoNgay[ngay];
            let tongHamLuong = 0;
            
            // Tính tổng hàm lượng trong ngày
            thuocTrongNgay.forEach(item => {
                const hamLuong = parseHamLuong(item.Ham_Luong);
                if (hamLuong !== null) {
                    tongHamLuong += hamLuong;
                }
            });

            const isNgayDauTien = ngay === ngayDauTien;

            if (isNgayDauTien) {
                // Ngày đầu tiên: tổng hàm lượng <= 500mg
                if (tongHamLuong > 500) {
                    result.isValid = false;
                    result.errors.push({
                        Id: thuocTrongNgay[0].id || thuocTrongNgay[0].Id,
                        Error: `Ngày đầu tiên sử dụng Azithromycin (${ngay}), tổng hàm lượng ${tongHamLuong.toFixed(2)}mg vượt quá 500mg (cho phép tối đa 500mg)`
                    });
                }
            } else {
                // Các ngày còn lại: tổng hàm lượng <= 250mg
                if (tongHamLuong > 250) {
                    result.isValid = false;
                    result.errors.push({
                        Id: thuocTrongNgay[0].id || thuocTrongNgay[0].Id,
                        Error: `Ngày ${ngay} sử dụng Azithromycin, tổng hàm lượng ${tongHamLuong.toFixed(2)}mg vượt quá 250mg (cho phép tối đa 250mg)`
                    });
                }
            }
        });

        // Kiểm tra sử dụng liên tiếp 5 ngày
        if (cacNgaySuDung.length >= 5) {
            for (let i = 0; i <= cacNgaySuDung.length - 5; i++) {
                let isLienTiep = true;
                const chuoiNgay = [];
                
                // Kiểm tra 5 ngày liên tiếp bắt đầu từ vị trí i
                for (let j = 0; j < 4; j++) {
                    const ngayHienTai = cacNgaySuDung[i + j];
                    const ngayTiepTheo = cacNgaySuDung[i + j + 1];
                    const khoangCach = tinhKhoangCachNgay(ngayHienTai, ngayTiepTheo);
                    
                    chuoiNgay.push(ngayHienTai);
                    
                    // Nếu khoảng cách không phải 1 ngày thì không liên tiếp
                    if (khoangCach !== 1) {
                        isLienTiep = false;
                        break;
                    }
                }
                
                if (isLienTiep) {
                    chuoiNgay.push(cacNgaySuDung[i + 4]); // Thêm ngày thứ 5
                    
                    // Tìm tất cả các thuốc trong 5 ngày này để báo lỗi
                    const thuocTrongChuoi = danhSachAzithromycin.filter(item => {
                        const ngay = getNgayFromNgayYl(item.Ngay_Yl);
                        return chuoiNgay.includes(ngay);
                    });
                    
                    result.isValid = false;
                    result.errors.push({
                        Id: thuocTrongChuoi[0].id || thuocTrongChuoi[0].Id,
                        Error: `Azithromycin không được sử dụng liên tiếp 5 ngày. Đã sử dụng từ ngày ${chuoiNgay[0]} đến ngày ${chuoiNgay[4]} (5 ngày liên tiếp)`
                    });
                    
                    // Chỉ báo lỗi 1 lần cho chuỗi đầu tiên tìm thấy
                    break;
                }
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Azithromycin quá liều: ${error.message}`);
        result.message = 'Lỗi khi validate Azithromycin quá liều';
    }

    return result;
};

module.exports = validateRule_Id_40;

