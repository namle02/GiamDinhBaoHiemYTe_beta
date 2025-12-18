/**
 * Rule 38: Điều dưỡng chỉ đinh sai dịch vụ
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */



const ma_dich_vu_sai = [
    '11.0132.1890',
    '11.0005.1148',
    '11.0010.1148',
    '11.0004.1149',
    '11.0009.1149',
    '11.0003.1150',
    '11.0008.1150',
    '01.0267.0203',
    '01.0267.0205',
    '01.0267.0204',
    '10.9003.0205',
    '10.9003.0200',
    '10.9003.0201',
    '10.9003.0204',
    '10.9003.0203',
    '10.9003.0202',
    '15.0303.2047',
    '15.0303.0204',
    '15.0303.0202',
    '15.0303.0205',
    '03.3911.0200',
    '03.3826.0075',
    '03.3826.0203',
    '03.3826.0205',
    '03.3826.0200',
    '03.3826.2047',
    '03.3826.0204',
    '03.3826.0202',
    '02.0163.0203',
    '11.0116.0199',
    '07.0225.0205',
    '07.0225.0200',
    '07.0225.0203',
    '07.0225.0201',
    '07.0225.0202',
    '07.0225.0204',
];

const validateRule_Id_38 = async (patientData) => {
    const result = {
        ruleName: 'Điều dưỡng chỉ đinh sai dịch vụ',
        ruleId: 'Rule_Id_38',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3;
        if (!xml3_data || !Array.isArray(xml3_data)) {
            throw new Error('Dữ liệu XML3 không hợp lệ hoặc thiếu');
        }

        // Lấy ra tất cả dịch vụ có mã sai
        const dichVuSai = xml3_data.filter(item => ma_dich_vu_sai.includes(item.Ma_Dich_Vu));

        for (const item of dichVuSai) {
           if(item.Chucdanh_id === 7232 || item.Chucdanh_id === 7362) {
            result.errors.push({
                Id: item.Id,
                Error: 'Điều dưỡng chỉ đinh sai dịch vụ'
            });
            result.isValid = false;
           }
        }
       

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Điều dưỡng chỉ đinh sai dịch vụ: ${error.message}`);
        result.message = 'Lỗi khi validate Điều dưỡng chỉ đinh sai dịch vụ';
    }

    return result;
};

module.exports = validateRule_Id_38;

