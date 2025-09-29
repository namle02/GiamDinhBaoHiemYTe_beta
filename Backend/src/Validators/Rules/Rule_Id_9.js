/**
 * Rule 9: Thanh toán dịch vụ “Bơm thông lệ đạo” đối với người bệnh không có bệnh chít hẹp điểm lệ, tắc lệ quản ngang hoặc ống lệ mũi.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_9 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán các DVKT phục hồi chức năng đối với các trường hợp chống chỉ định cho người bệnh có khối u ác tính (ung thư) theo quy định tại Quyết định số 54/QĐ-BYT và Quyết định số 5737/QĐ-BYT “Hướng dẫn quy trình kỹ thuật chuyên ngành phục hồi chức năng”, Quyết định số 26/QĐ-BYT quy trình kỹ thuật y học cổ truyền',
        ruleId: 'Rule_Id_9',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        for (const item of patientData.Xml3) {
            const Ma_Dich_Vu = item.Ma_Dich_Vu;
            const Ma_Benh = item.Ma_Benh;
            
            if (Ma_Dich_Vu === '17.0007.0234' || Ma_Dich_Vu === '17.0009.0255'
                || Ma_Dich_Vu === '17.0018.0221' || Ma_Dich_Vu === '17.0026.0220'
                || Ma_Dich_Vu === '17.0011.0237' || Ma_Dich_Vu === '17.0001.0254'
                || Ma_Dich_Vu === '17.0004.0232') {
                    let coMaBenhUngThu = false;
                    for (let i = 0; i <= 97; i++) {
                        const code = i < 10 ? `C0${i}` : `C${i}`;
                        if (Ma_Benh && Ma_Benh.includes(code)) {
                            coMaBenhUngThu = true;
                            break;
                        }
                    }
                    if (coMaBenhUngThu) {
                        result.isValid = false;
                        result.errors.push({ Id: item.Id, Error: 'Bệnh nhân có mã bệnh ung thư ác tính ( C00 - C97), không thanh toán DVKT phục hồi chức năng' });
                    }
                }
        }
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Thanh toán các DVKT phục hồi chức năng đối với các trường hợp chống chỉ định cho người bệnh có khối u ác tính (ung thư) theo quy định tại Quyết định số 54/QĐ-BYT và Quyết định số 5737/QĐ-BYT “Hướng dẫn quy trình kỹ thuật chuyên ngành phục hồi chức năng”, Quyết định số 26/QĐ-BYT quy trình kỹ thuật y học cổ truyền: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán các DVKT phục hồi chức năng đối với các trường hợp chống chỉ định cho người bệnh có khối u ác tính (ung thư) theo quy định tại Quyết định số 54/QĐ-BYT và Quyết định số 5737/QĐ-BYT “Hướng dẫn quy trình kỹ thuật chuyên ngành phục hồi chức năng”, Quyết định số 26/QĐ-BYT quy trình kỹ thuật y học cổ truyền';
    }

    return result;
};

module.exports = validateRule_Id_9;