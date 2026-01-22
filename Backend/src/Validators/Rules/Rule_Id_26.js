/**
 * Rule 26: Thanh toán thuốc chứa hoạt chất Peptid không đúng quy định tại Thông tư số 20/2022/TT-BYT
 * Thuốc 40.561 chỉ được sử dụng khi:
 * - Ma_Benh thuộc I60-I68, S06, S02 HOẶC
 * - Ma_Dich_Vu thuộc danh sách phẫu thuật thần kinh sọ não
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_26 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán thuốc chứa hoạt chất Peptid không đúng quy định tại Thông tư số 20/2022/TT-BYT',
        ruleId: 'Rule_Id_26',
        isValid: true,
        validateField: 'Ma_Thuoc',
        validateFile:'XML2',
        message: '',
        errors: [],
        warnings: []
    };

    // Danh sách mã dịch vụ phẫu thuật thần kinh sọ não hợp lệ
    const maDichVuHopLe = [
        '10.0128.0369', '10.0127.0369', '10.0072.0369', '10.0063.0369', '10.1110.0369',
        '10.1051.0369', '10.0073.0369', '10.0074.0369', '10.0011.0370', '10.0024.0370',
        '10.0008.0370', '10.0010.0370', '10.0009.0370', '10.0006.0370', '10.0007.0370',
        '10.0005.0370', '10.0023.0370', '10.0012.0370', '10.1097.0370', '10.1096.0370',
        '10.0015.0370', '10.0147.0371', '10.0031.0372', '10.0030.0372', '10.0025.0372',
        '10.0026.0372', '10.0027.0372', '10.0028.0372', '10.0033.0372', '10.0034.0372',
        '10.0060.0373', '10.0035.0373', '10.0061.0373', '10.0062.0373', '10.0058.0373',
        '10.0016.0373', '10.0059.0373', '10.0018.0373', '10.0019.0373', '10.0020.0373',
        '10.0064.0373', '10.0046.0374', '10.0049.0374', '10.0048.0374', '10.0050.0374',
        '10.0051.0374', '10.0053.0374', '10.0052.0374', '10.1094.0374', '10.0115.0375',
        '10.0113.0375', '10.0076.0376', '10.0022.0376', '10.0021.0376', '10.1099.0376',
        '10.0044.0377', '10.0042.0377', '10.0043.0377', '10.0047.0377', '10.0065.0377',
        '10.0067.0377', '10.0068.0377', '10.0071.0377', '10.0070.0377', '10.0069.0377',
        '10.0078.0377', '10.0077.0377', '10.0079.0377', '10.0055.0378', '10.0041.0378',
        '10.0126.0379', '10.0105.0379', '10.0103.0379', '10.0093.0380', '10.0094.0380',
        '10.0101.0380', '10.0096.0380', '10.0090.0380', '10.0089.0380', '10.0088.0380',
        '10.0091.0380', '10.0095.0380', '10.0097.0380', '10.0092.0380', '10.0117.0381',
        '10.0119.0381', '10.0104.0381', '10.0106.0381', '10.0083.0381', '10.0085.0381',
        '10.0084.0381', '10.0110.0381', '10.0109.0381', '10.0111.0381', '10.0102.0381',
        '10.0121.0381', '10.0118.0381', '10.0120.0381', '10.0108.0382', '10.0107.0382',
        '10.0112.0382', '10.0029.0383', '10.0017.0384', '10.0124.0385', '10.0145.0385',
        '10.0144.0385', '10.0146.0385', '10.0122.0385', '10.0003.0386', '10.0002.0386',
        '10.0004.0386', '10.0013.0386', '10.0014.0386', '10.0087.0387', '10.0082.0387',
        '10.0081.0387', '10.0080.0387', '10.0086.0388'
    ];

    // Danh sách mã bệnh hợp lệ (I60-I68, S06, S02)
    const maBenhHopLe = ['I60', 'I61', 'I62', 'I63', 'I64', 'I65', 'I66', 'I67', 'I68', 'S06', 'S02'];

    try {
        const xml2_data = patientData.Xml2 || [];
        const xml3_data = patientData.Xml3 || [];
        
        // Lấy danh sách mã thuốc
        const danhsachthuoc = xml2_data.map(item => item.Ma_Thuoc);

        // Nếu có mã thuốc 40.561 thì kiểm tra
        if (danhsachthuoc.includes('40.561')) {
            // Lấy tất cả mã bệnh của các dịch vụ có mã 40.561
            const maBenhLienQuan = xml2_data
                .filter(item => item.Ma_Thuoc === '40.561')
                .map(item => item.Ma_Benh)
                .filter(Boolean);

            // Kiểm tra mã bệnh hợp lệ
            const coMaBenhHopLe = maBenhLienQuan.some(maBenhStr => {
                const arrMaBenh = maBenhStr.split(';').map(s => s.trim().toUpperCase()).filter(Boolean);
                return arrMaBenh.some(ma => maBenhHopLe.some(code => ma.startsWith(code)));
            });

            // Lấy tất cả mã dịch vụ từ XML3
            const danhSachMaDichVu = xml3_data.map(item => item.Ma_Dich_Vu).filter(Boolean);
            
            // Kiểm tra mã dịch vụ hợp lệ
            const coMaDichVuHopLe = danhSachMaDichVu.some(maDV => maDichVuHopLe.includes(maDV));

            // Nếu không có mã bệnh hợp lệ VÀ không có mã dịch vụ hợp lệ thì báo lỗi
            if (!coMaBenhHopLe && !coMaDichVuHopLe) {
                result.isValid = false;
                xml2_data.filter(it => it.Ma_Thuoc === '40.561').forEach(it => {
                    result.errors.push({ 
                        Id: it.id || it.Id, 
                        Error: 'Thuốc 40.561 không có mã bệnh hợp lệ (I60-I68, S06, S02) và không có mã dịch vụ phẫu thuật thần kinh sọ não hợp lệ' 
                    });
                });
                result.message = 'Không hợp lệ thuốc 40.561 do thiếu mã bệnh hoặc mã dịch vụ phù hợp';
            }
        }   
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Rule 26: ${error.message}`);
        result.message = 'Lỗi khi validate thuốc 40.561';
    }

    return result;
};

module.exports = validateRule_Id_26;