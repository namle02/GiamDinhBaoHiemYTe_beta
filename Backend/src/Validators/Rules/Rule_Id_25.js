/**
 * Rule 25: Thanh toán giường điều trị nội trú ban ngày tại cơ sở khám bệnh chữa bệnh YHCT không đúng quy định tại Thông tư số 01/2019/TT-BYT ngày 01/3/2019 của Bộ trưởng Bộ Y tế quy định việc thực hiện điều trị nội trú ban ngày tại cơ sở khám bệnh, chữa bệnh y học cổ truyền và Công văn số 4712/BYT-YDCT ngày 15/ 8/ 2019 hướng dẫn thực hiện Thông tư số 01/2019/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_25 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán giường điều trị nội trú ban ngày tại cơ sở khám bệnh chữa bệnh YHCT không đúng quy định tại Thông tư số 01/2019/TT-BYT ngày 01/3/2019 của Bộ trưởng Bộ Y tế quy định việc thực hiện điều trị nội trú ban ngày tại cơ sở khám bệnh, chữa bệnh y học cổ truyền và Công văn số 4712/BYT-YDCT ngày 15/ 8/ 2019 hướng dẫn thực hiện Thông tư số 01/2019/TT-BYT',
        ruleId: 'Rule_Id_25',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        const xml2_data = patientData.Xml2 || [];

        // Danh sách mã dịch vụ cần kiểm tra (phải có mã nhóm = 15)
        const danhSachMaDichVuCanKiemTra = [
            'K16.GBN.2',
            'K33.GBN.1',
            'K16.GBN.3',
            'K31.1962',
            'K31.1968'
        ];

        // Kiểm tra xem có dịch vụ nào thuộc danh sách và có mã nhóm = 15 không
        const coDichVuCanKiemTra = xml3_data.some(item => 
            danhSachMaDichVuCanKiemTra.includes(item.Ma_Dich_Vu) && 
            item.Ma_Nhom == 15
        );

        // Nếu có dịch vụ cần kiểm tra, tiếp tục validate
        if (coDichVuCanKiemTra) {
            // Kiểm tra xem có dịch vụ có mã dịch vụ bắt đầu bằng "08." hoặc "17." không
            const coDichVu08Hoac17 = xml3_data.some(item => {
                const maDichVu = item.Ma_Dich_Vu ? String(item.Ma_Dich_Vu) : '';
                return maDichVu.startsWith('08.') || maDichVu.startsWith('17.');
            });

            // Nếu có dịch vụ 08. hoặc 17. → đúng (không báo lỗi)
            if (coDichVu08Hoac17) {
                // Không báo lỗi, return result
                return result;
            }

            // Nếu không có dịch vụ 08. hoặc 17., kiểm tra DUONG_DUNG của xml2
            const danhSachDuongDungHopLe = ['2.01', '2.02', '2.04', '2.05', '2.08', '2.10', '2.14', '2.15'];
            
            // Kiểm tra xem có thuốc nào có DUONG_DUNG thuộc danh sách hợp lệ không
            const coDuongDungHopLe = xml2_data.some(item => {
                const duongDung = item.Duong_Dung ? String(item.Duong_Dung).trim() : '';
                return danhSachDuongDungHopLe.includes(duongDung);
            });

            // Nếu không có DUONG_DUNG hợp lệ → báo lỗi
            if (!coDuongDungHopLe) {
                result.isValid = false;
                // Báo lỗi cho tất cả các dịch vụ thuộc danh sách cần kiểm tra
                xml3_data.forEach(item => {
                    if (danhSachMaDichVuCanKiemTra.includes(item.Ma_Dich_Vu) && item.Ma_Nhom == 15) {
                        result.errors.push({ 
                            Id: item.id || item.Id, 
                            Error: `Dịch vụ ${item.Ma_Dich_Vu} không hợp lệ: không có dịch vụ mã 08. hoặc 17. và không có thuốc có đường dùng thuộc danh sách hợp lệ (2.01, 2.02, 2.04, 2.05, 2.08, 2.10, 2.14, 2.15)` 
                        });
                    }
                });
                result.message = 'Dịch vụ giường ban ngày nội khoa không hợp lệ: thiếu dịch vụ mã 08./17. hoặc thuốc có đường dùng hợp lệ.';
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán giường điều trị nội trú ban ngày tại cơ sở khám bệnh chữa bệnh YHCT không đúng quy định tại Thông tư số 01/2019/TT-BYT ngày 01/3/2019 của Bộ trưởng Bộ Y tế quy định việc thực hiện điều trị nội trú ban ngày tại cơ sở khám bệnh, chữa bệnh y học cổ truyền và Công văn số 4712/BYT-YDCT ngày 15/ 8/ 2019 hướng dẫn thực hiện Thông tư số 01/2019/TT-BYT: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán giường điều trị nội trú ban ngày tại cơ sở khám bệnh chữa bệnh YHCT không đúng quy định tại Thông tư số 01/2019/TT-BYT ngày 01/3/2019 của Bộ trưởng Bộ Y tế quy định việc thực hiện điều trị nội trú ban ngày tại cơ sở khám bệnh, chữa bệnh y học cổ truyền và Công văn số 4712/BYT-YDCT ngày 15/ 8/ 2019 hướng dẫn thực hiện Thông tư số 01/2019/TT-BYT';
    }

    return result;
};

module.exports = validateRule_Id_25;