/**
 * Rule 27: Thanh toán hoạt chất Moxifloxacin chỉ định sử dụng không phù hợp với tờ hướng dẫn sử dụng
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_27 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán hoạt chất Moxifloxacin chỉ định sử dụng không phù hợp với tờ hướng dẫn sử dụng',
        ruleId: 'Rule_Id_27',
        isValid: true,
        validateField: 'Ma_Thuoc',
        validateFile:'XML2',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy dữ liệu thuốc từ Xml2
        const xml2_data = patientData.Xml2 || [];
        // Lấy dữ liệu hành chính từ Xml1 (nếu có)
        const xml1_data = patientData.Xml1[0] || {};
        // Lấy thông tin ngày sinh từ hồ sơ bệnh nhân (chỉ có trường ngay_sinh, dạng: 194702020000)
        const ngaySinh = xml1_data.Ngay_Sinh || xml1_data.ngay_sinh || null;

        // Hàm tính tuổi từ ngày sinh dạng yyyymmddxxxx (ví dụ: 194702020000)
        function tinhTuoiTuNgaySinh12(ngaySinhStr) {
            if (!ngaySinhStr || typeof ngaySinhStr !== 'string' || ngaySinhStr.length < 8) return null;
            const ns = ngaySinhStr.substring(0, 8);
            const nam = Number(ns.substring(0, 4));
            const thang = Number(ns.substring(4, 6));
            const ngay = Number(ns.substring(6, 8));
            if (isNaN(nam) || isNaN(thang) || isNaN(ngay)) return null;
            const today = new Date();
            const birthDate = new Date(nam, thang - 1, ngay);
            let tuoi = today.getFullYear() - birthDate.getFullYear();
            const m = today.getMonth() - birthDate.getMonth();
            if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
                tuoi--;
            }
            return tuoi;
        }

        // Mã bệnh có thể nằm trong nhiều trường, lấy tất cả mã bệnh liên quan
        let dsMaBenh = [];

        if (xml1_data.Ma_Benh_Kt) {
            if (typeof xml1_data.Ma_Benh_Kt == 'string') {
                dsMaBenh = xml1_data.Ma_Benh_Kt.split(';').map(s => s.trim().toUpperCase()).filter(Boolean);
            } else if (Array.isArray(xml1_data.Ma_Benh_Kt)) {
                dsMaBenh = xml1_data.Ma_Benh_Kt.flatMap(mb => (typeof mb === 'string' ? mb.split(';').map(s => s.trim().toUpperCase()) : [])).filter(Boolean);
            }
        }

        dsMaBenh = Array.from(new Set(dsMaBenh)); // loại trùng

        // Thêm trực tiếp xml1_data.Ma_Benh_Chinh vào dsMaBenh
        if (xml1_data.Ma_Benh_Chinh) {
            dsMaBenh.push(xml1_data.Ma_Benh_Chinh.toUpperCase());
        }

        // Kiểm tra có thuốc Moxifloxacin (mã 40.231) không
        // Lấy danh sách tất cả thuốc Moxifloxacin (mã 40.231)
        const moxiList = xml2_data.filter(item => String(item.Ma_Thuoc).trim() === '40.231');
        const coMoxifloxacin = moxiList.length > 0;
        if (!coMoxifloxacin) {
            return result; // Không có thuốc, không cần kiểm tra
        }

        // Danh sách mã bệnh hợp lệ
        const maBenhHopLe = [
            /^J15\.\d*$/i, // J15.x
            /^J18\.\d*$/i, // J18.x
            /^J44\.1$/i,   // J44.1
            /^J01\.\d*$/i, // J01.x 
            /^A41\.\d*$/i, // A41.x
            /^N39\.0$/i,   // N39.0
            /^K65\.\d*$/i  // K65.x
        ];

        // Danh sách mã bệnh lao trẻ em ngoại lệ A15-A19
        const isLaoTreEm = dsMaBenh.some(ma => /^A1[5-9](\.\d*)?$/i.test(ma));

        // Kiểm tra có ít nhất 1 mã bệnh hợp lệ
        let coMaBenhHopLe = false;
        let canhBaoJ01 = false;
        for (let ma of dsMaBenh) {
            for (let idx = 0; idx < maBenhHopLe.length; idx++) {
                if (maBenhHopLe[idx].test(ma)) {
                    coMaBenhHopLe = true;
                    if (idx === 3) canhBaoJ01 = true; // J01.x
                }
            }
        }

        // Kiểm tra mã bệnh thuộc nhóm O00-O99 (phụ nữ có thai, sinh, hậu sản, cho con bú)
        const coMaBenhO = dsMaBenh.some(ma => {
            if (/^O\d{2}/i.test(ma)) {
                const so = parseInt(ma.substring(1, 3), 10);
                return so >= 0 && so <= 99;
            }
            return false;
        });

        // Kiểm tra tuổi
        let tuoiSo = null;
        if (ngaySinh) {
            tuoiSo = tinhTuoiTuNgaySinh12(ngaySinh);
        }

        // Logic kiểm tra và thêm errors/warnings có ID hợp lệ (theo từng thuốc Moxifloxacin)
        // Chúng ta sẽ lặp qua từng thuốc Moxifloxacin để add error/warning gắn Id vào object
        if (!coMaBenhHopLe) {
            result.isValid = false;
            moxiList.forEach(it => {
                result.errors.push({ Id: it.Id, Error: 'Moxifloxacin (40.231) không có mã bệnh phù hợp (J15.x, J18.x, J44.1, J01.x, A41.x, N39.0, K65.x)' });
            });
        }
        // Kiểm tra trẻ em < 18 tuổi trừ trường hợp trẻ em mắc bệnh lao (A15, A16, A17, A18, A19)
        if (tuoiSo !== null && tuoiSo < 18 && !isLaoTreEm) {
            result.isValid = false;
            moxiList.forEach(it => {
                result.errors.push({
                    Id: it.Id,
                    Error: 'Bệnh nhân sử dụng Moxifloxacin (mã 40.231) nhưng chưa đủ 18 tuổi (không thuộc trường hợp trẻ em mắc bệnh lao A15-A19).'
                });
            });
        }
        if (coMaBenhO) {
            result.isValid = false;
            moxiList.forEach(it => {
                result.errors.push({
                    Id: it.Id,
                    Error: 'Bệnh nhân sử dụng Moxifloxacin (mã 40.231) nhưng có mã bệnh thuộc nhóm O00-O99 (phụ nữ có thai, sinh, hậu sản, cho con bú).'
                });
            });
        }
        if (canhBaoJ01) {
            moxiList.forEach(it => {
                result.warnings.push({
                    Id: it.Id,
                    Warning: 'Chỉ định Moxifloxacin cho mã bệnh J01.x (viêm xoang cấp) chỉ hợp lệ khi có chứng minh thất bại điều trị trước bằng kháng sinh khác.'
                });
            });
        }

        if (result.errors.length > 0) {
            result.message = 'Có sử dụng Moxifloxacin nhưng không đáp ứng đủ điều kiện chỉ định theo hướng dẫn sử dụng.';
        }

    } catch (error) {
        result.isValid = false;
        // Nếu không lấy được Id thuốc, gán Id là null
        result.errors.push({
            Id: null,
            Error: `Lỗi khi validate Thanh toán hoạt chất Moxifloxacin chỉ định sử dụng không phù hợp với tờ hướng dẫn sử dụng: ${error.message}`
        });
        result.message = 'Lỗi khi validate Thanh toán hoạt chất Moxifloxacin chỉ định sử dụng không phù hợp với tờ hướng dẫn sử dụng';
    }

    return result;
};


module.exports = validateRule_Id_27;