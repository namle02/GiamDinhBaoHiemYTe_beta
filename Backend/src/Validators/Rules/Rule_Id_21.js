/**
 * Rule 21: Thanh toán số ngày giường điều trị nội trú không đúng quy định tại điểm a và điểm b khoản 1 Điều 6 Thông tư số 22/2023/TT-BYT.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_21 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán số ngày giường điều trị nội trú không đúng quy định tại điểm a và điểm b khoản 1 Điều 6 Thông tư số 22/2023/TT-BYT.',
        ruleId: 'Rule_Id_21',
        isValid: true,
        validateField: 'Ngay_Yl',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy số ngày điều trị từ xml1
        const xml1 = patientData.Xml1[0] || {};
        const soNgayDieuTri = Number(xml1.So_Ngay_Dtri) || 0;

        // Lấy danh sách dịch vụ từ xml3
        const xml3 = patientData.Xml3 || [];

        // Lọc các dịch vụ có mã nhóm là '15'
        const dichVuNhom15 = xml3.filter(item => item.Ma_Nhom == '15' && item.Ngay_Yl);

        // Lấy danh sách các ngày y lệnh (chỉ lấy 8 ký tự đầu tiên yyyyMMdd)
        const ngayYlList = dichVuNhom15
            .map(item => item.Ngay_Yl && item.Ngay_Yl.toString().substring(0, 8))
            .filter(ngay => !!ngay)
            .sort();

        let soNgayGiuong = 0;
        if (ngayYlList.length > 0) {
            const ngayMin = ngayYlList[0];
            const ngayMax = ngayYlList[ngayYlList.length - 1];

            // Chuyển yyyyMMdd thành đối tượng Date
            const dateMin = new Date(
                Number(ngayMin.substring(0, 4)),
                Number(ngayMin.substring(4, 6)) - 1,
                Number(ngayMin.substring(6, 8))
            );
            const dateMax = new Date(
                Number(ngayMax.substring(0, 4)),
                Number(ngayMax.substring(4, 6)) - 1,
                Number(ngayMax.substring(6, 8))
            );

            // Số ngày giường = (ngày lớn nhất - ngày nhỏ nhất) + 1
            const diffTime = dateMax - dateMin;
            soNgayGiuong = Math.floor(diffTime / (1000 * 60 * 60 * 24)) + 1;
        }

        if (soNgayDieuTri < soNgayGiuong) {
            result.isValid = false;
            // Gắn lỗi vào tất cả các bản ghi nhóm 15 để phía client highlight theo ngày y lệnh
            dichVuNhom15.forEach(item => {
                result.errors.push({ Id: item.Id, Error: `Số ngày điều trị (${soNgayDieuTri}) < số ngày giường theo ngày y lệnh (${soNgayGiuong})` });
            });
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi kiểm tra số ngày điều trị và số ngày giường: ${error.message}`);
        result.message = 'Lỗi khi validate số ngày điều trị và số ngày giường';
    }

    return result;
};

module.exports = validateRule_Id_21;