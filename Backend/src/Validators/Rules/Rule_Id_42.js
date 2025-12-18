/**
 * Rule 42: Glucosamin sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_42 = async (patientData) => {
    const result = {
        ruleName: 'Glucosamin sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT',
        ruleId: 'Rule_Id_42',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile: 'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml1_data = patientData.Xml1 || [];
        const xml2_data = patientData.Xml2 || [];

        const dsMaBenh = xml1_data.map(item => item.Ma_Benh_Chinh);
        const dsMaBenhKt = xml1_data.map(item => item.Ma_Benh_Kt);

        const maBenhHopLe = /^A1[5-9](\.\d*)?$/i;

        xml2_data.forEach(thuoc => {
            if (thuoc.Ma_Thuoc === '40.64') {
                if (!dsMaBenh.some(ma => maBenhHopLe.test(ma)) || !dsMaBenhKt.some(ma => maBenhHopLe.test(ma))) {
                    result.isValid = false;
                    result.errors.push({ Id: thuoc.Id, Error: 'Glucosamin (40.64) chỉ được sử dụng khi có mã bệnh M17' });
                }
            }
        });

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Glucosamin sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT: ${error.message}`);
        result.message = 'Lỗi khi validate Glucosamin sử dụng không đúng quy định Thông tư số 20/2022/TT-BYT';
    }

    return result;
};

module.exports = validateRule_Id_42;