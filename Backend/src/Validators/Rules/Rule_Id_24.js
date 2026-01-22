/**
 * Rule 24: Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const Doctor = require('../../Repos/Models/Doctor');

const validateRule_Id_24 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh',
        ruleId: 'Rule_Id_24',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const danhsachdichvu = [
            '03.4183.0271',
            '08.0006.0271',
            '08.0367.0271',
            '08.0378.0271'
        ];

        const xml3_data = patientData.Xml3 || [];

        // Đếm số dịch vụ thủy châm
        const dichVuThuyCham = xml3_data.filter(item => danhsachdichvu.includes(item.Ma_Dich_Vu));

        for (const item of xml3_data) {
            if (danhsachdichvu.includes(item.Ma_Dich_Vu)) {
                // Chỉ kiểm tra người thực hiện
                const maBacSiThucHien = item.Nguoi_Thuc_Hien;
                
                let isValidThucHien = true;

                // Kiểm tra người thực hiện
                if (maBacSiThucHien && maBacSiThucHien !== '') {
                    const doctorThucHien = await Doctor.findOne({ MACCHN: maBacSiThucHien }).lean();
                    
                    if (!doctorThucHien) {
                        isValidThucHien = false;
                    } else {
                        if (Array.isArray(doctorThucHien.PHAMVI_CM)) {
                            const phamViCM = doctorThucHien.PHAMVI_CM;
                            
                            // Kiểm tra các điều kiện hợp lệ:
                            // 1. PHAMVI_CM chứa 108 → hợp lệ
                            // 2. HOẶC PHAMVI_CM chứa 310 → hợp lệ
                            // 3. HOẶC PHAMVI_CM chứa 301 VÀ DVKT_KHAC chứa '08.0006' → hợp lệ
                            const coMa108 = phamViCM.includes(108);
                            const coMa310 = phamViCM.includes(310);
                            const coMa301 = phamViCM.includes(301);
                            
                            let coDvktKhac = false;
                            if (coMa301) {
                                // Kiểm tra DVKT_KHAC nếu có mã 301
                                if (Array.isArray(doctorThucHien.DVKT_KHAC)) {
                                    coDvktKhac = doctorThucHien.DVKT_KHAC.includes('08.0006');
                                } else if (typeof doctorThucHien.DVKT_KHAC === 'string') {
                                    // Xử lý trường hợp DVKT_KHAC là string (có thể có dạng "08.0006;08.0007")
                                    coDvktKhac = doctorThucHien.DVKT_KHAC.split(';').map(s => s.trim()).includes('08.0006');
                                }
                            }
                            
                            // Hợp lệ nếu: có 108 HOẶC có 310 HOẶC (có 301 VÀ có 08.0006 trong DVKT_KHAC)
                            if (!coMa108 && !coMa310 && !(coMa301 && coDvktKhac)) {
                                isValidThucHien = false;
                            }
                        } else {
                            isValidThucHien = false;
                        }
                    }
                } else {
                    isValidThucHien = false; // Nếu không có mã thì cũng coi là không hợp lệ
                }

                if (!isValidThucHien) {
                    result.isValid = false;
                    result.errors.push({ Id: item.id || item.Id, Error: 'Thủy châm: người thực hiện không đúng chức danh chuyên môn (TT 32/2023/TT-BYT)' });
                }
            }
        }

        if (result.errors.length > 0) {
            result.isValid = false;
            result.message = 'Có dịch vụ thủy châm do người thực hiện không đúng chức danh chuyên môn theo quy định.';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán chi phí các dịch vụ kỹ thuật thủy châm do người chỉ định hoặc người thực hiện không đúng chức danh chuyên môn của người hành nghề được quy ddịnh tại Điều 11 Thông tư số 32/2023/TT-BYT ngày 31/12/2023 của Bộ Y tế quy định chi tiết một số điều của luật khám bệnh, chữa bệnh';
    }

    return result;
};

module.exports = validateRule_Id_24;