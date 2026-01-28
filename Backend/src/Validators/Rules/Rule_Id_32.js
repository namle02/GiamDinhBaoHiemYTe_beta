/**
 * Rule 32: Thanh toán các thuốc chứa hoạt chất "Omeprazol mã chi phí (40.677); Esomeprazol mã chi phí (40.678); Pantoprazol mã chi phí (40.679); Rabeprazol mã chi phí (40.680) không đúng quy định tại Thông tư số 20/2022/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_32 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán các thuốc chứa hoạt chất "Omeprazol mã chi phí (40.677); Esomeprazol mã chi phí (40.678); Pantoprazol mã chi phí (40.679); Rabeprazol mã chi phí (40.680) không đúng quy định tại Thông tư số 20/2022/TT-BYT',
        ruleId: 'Rule_Id_32',
        isValid: true,
        validateField: 'Ma_Thuoc',
        validateFile: 'XML2',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách thuốc từ Xml2
        const dsThuoc = Array.isArray(patientData.Xml2) ? patientData.Xml2 : [];
        
        // Danh sách mã thuốc cần kiểm tra
        const dsMaThuocCheck = ['40.677', '40.678', '40.679', '40.680'];
        
        // Kiểm tra xem bệnh nhân có thuốc nào thuộc danh sách không
        const thuocCanKiemTra = dsThuoc.filter(thuoc => {
            const maThuoc = thuoc.Ma_Thuoc ? String(thuoc.Ma_Thuoc).trim() : null;
            return maThuoc && dsMaThuocCheck.includes(maThuoc);
        });

        // Nếu không có thuốc cần kiểm tra thì không cần validate
        if (thuocCanKiemTra.length === 0) {
            return result;
        }

        // Lấy dữ liệu bệnh từ Xml1 (chỉ lấy phần tử đầu tiên)
        const xml1 = Array.isArray(patientData.Xml1) && patientData.Xml1.length > 0 ? patientData.Xml1[0] : {};

        // Lấy danh sách mã bệnh từ các trường
        let dsMaBenh = [];

        if (xml1.Ma_Benh_Kt) {
            if (typeof xml1.Ma_Benh_Kt === 'string') {
                dsMaBenh = dsMaBenh.concat(xml1.Ma_Benh_Kt.split(';').map(s => s.trim().toUpperCase()).filter(Boolean));
            } else if (Array.isArray(xml1.Ma_Benh_Kt)) {
                dsMaBenh = dsMaBenh.concat(
                    xml1.Ma_Benh_Kt.flatMap(mb => (typeof mb === 'string' ? mb.split(';').map(s => s.trim().toUpperCase()) : []))
                );
            }
        }
        if (xml1.Ma_Benh_Yhct) {
            if (typeof xml1.Ma_Benh_Yhct === 'string') {
                dsMaBenh = dsMaBenh.concat(xml1.Ma_Benh_Yhct.split(';').map(s => s.trim().toUpperCase()).filter(Boolean));
            } else if (Array.isArray(xml1.Ma_Benh_Yhct)) {
                dsMaBenh = dsMaBenh.concat(
                    xml1.Ma_Benh_Yhct.flatMap(mb => (typeof mb === 'string' ? mb.split(';').map(s => s.trim().toUpperCase()) : []))
                );
            }
        }
        if (xml1.Ma_Benh_Chinh) {
            dsMaBenh.push(String(xml1.Ma_Benh_Chinh).trim().toUpperCase());
        }

        dsMaBenh = Array.from(new Set(dsMaBenh)); // loại trùng

        // Kiểm tra điều kiện 1: Mã bệnh K21 hoặc K25->K31
        const regexMaBenh = [
            /^K21$/i,           // K21
            /^K2[5-9]$/i,       // K25->K29
            /^K3[0-1]$/i        // K30->K31
        ];

        const coMaBenhHopLe = dsMaBenh.some(ma => regexMaBenh.some(regex => regex.test(ma)));
        
        // Nếu có mã bệnh hợp lệ → ĐÚNG (thỏa mãn điều kiện 1)
        if (coMaBenhHopLe) {
            return result;
        }

        // Kiểm tra điều kiện 2: Dịch vụ trong XML3
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        const dsDichVuCheck = ['K48.1902', 'K48.HSTC'];
        
        // Lọc các dịch vụ có mã trong danh sách
        const dichVuCanKiemTra = xml3_data.filter(item => {
            const maDichVu = item.Ma_Dich_Vu ? String(item.Ma_Dich_Vu).trim() : null;
            return maDichVu && dsDichVuCheck.includes(maDichVu);
        });

        // Nếu không có dịch vụ cần kiểm tra → SAI (không thỏa mãn cả 2 điều kiện)
        if (dichVuCanKiemTra.length === 0) {
            thuocCanKiemTra.forEach(thuoc => {
                result.isValid = false;
                result.errors.push({ 
                    Id: thuoc.id || thuoc.Id, 
                    Error: `Thuốc ${thuoc.Ma_Thuoc} (PPI) không đáp ứng điều kiện: cần có mã bệnh K21/K25->K31 hoặc dịch vụ K48.1902/K48.HSTC với tổng số ngày >= 5` 
                });
            });
            return result;
        }

        // Hàm lấy phần ngày từ Ngay_Yl hoặc Ngay_Kq (dạng yyyyMMddHHmm - 14 ký tự)
        // Trả về yyyyMMdd (8 ký tự đầu)
        function getNgayFromString(ngayStr) {
            if (!ngayStr) return null;
            const str = String(ngayStr).trim();
            // Lấy 8 ký tự đầu (yyyyMMdd)
            return str.length >= 8 ? str.substring(0, 8) : str;
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
            const diffTime = date2 - date1;
            return Math.floor(diffTime / (1000 * 60 * 60 * 24));
        }

        // Lấy tất cả các ngày_yl và ngày_kq từ các dịch vụ
        const danhSachNgayYl = [];
        const danhSachNgayKq = [];

        dichVuCanKiemTra.forEach(item => {
            const ngayYl = getNgayFromString(item.Ngay_Yl);
            const ngayKq = getNgayFromString(item.Ngay_Kq);
            
            if (ngayYl) {
                danhSachNgayYl.push(ngayYl);
            }
            if (ngayKq) {
                danhSachNgayKq.push(ngayKq);
            }
        });

        if (danhSachNgayYl.length === 0 || danhSachNgayKq.length === 0) {
            // Không đủ dữ liệu ngày → SAI (không thể kiểm tra điều kiện dịch vụ)
            thuocCanKiemTra.forEach(thuoc => {
                result.isValid = false;
                result.errors.push({ 
                    Id: thuoc.id || thuoc.Id, 
                    Error: `Thuốc ${thuoc.Ma_Thuoc} (PPI) không đáp ứng điều kiện: dịch vụ K48.1902/K48.HSTC thiếu thông tin ngày y lệnh hoặc ngày kết quả` 
                });
            });
            return result;
        }

        // Sắp xếp và lấy ngày_yl lâu nhất (nhỏ nhất) và ngày_kq mới nhất (lớn nhất)
        danhSachNgayYl.sort();
        danhSachNgayKq.sort();
        
        const ngayYlLauNhat = danhSachNgayYl[0]; // Ngày y lệnh lâu nhất
        const ngayKqMoiNhat = danhSachNgayKq[danhSachNgayKq.length - 1]; // Ngày kết quả mới nhất

        // Tính tổng số ngày sử dụng = ngày kq mới nhất - ngày yl lâu nhất
        const tongSoNgay = tinhKhoangCachNgay(ngayYlLauNhat, ngayKqMoiNhat);

        if (tongSoNgay === null) {
            // Không thể tính được → SAI (không thể kiểm tra điều kiện dịch vụ)
            thuocCanKiemTra.forEach(thuoc => {
                result.isValid = false;
                result.errors.push({ 
                    Id: thuoc.id || thuoc.Id, 
                    Error: `Thuốc ${thuoc.Ma_Thuoc} (PPI) không đáp ứng điều kiện: không thể tính tổng số ngày sử dụng dịch vụ K48.1902/K48.HSTC` 
                });
            });
            return result;
        }

        if (tongSoNgay < 5) {
            // Tổng số ngày < 5 → SAI (không thỏa mãn điều kiện dịch vụ)
            thuocCanKiemTra.forEach(thuoc => {
                result.isValid = false;
                result.errors.push({ 
                    Id: thuoc.id || thuoc.Id, 
                    Error: `Thuốc ${thuoc.Ma_Thuoc} (PPI) không đáp ứng điều kiện: tổng số ngày sử dụng dịch vụ K48.1902/K48.HSTC (${tongSoNgay} ngày) nhỏ hơn 5 ngày` 
                });
            });
            return result;
        }

        // Tổng số ngày >= 5 → ĐÚNG (thỏa mãn điều kiện 2)
        return result;

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Rule 32: ${error.message}`);
        result.message = 'Lỗi khi validate Rule 32';
    }

    return result;
};

module.exports = validateRule_Id_32;
