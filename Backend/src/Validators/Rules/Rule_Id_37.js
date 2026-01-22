/**
 * Rule 37: Điều dường không được chỉ định thuốc 
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */


const validateRule_Id_37 = async (patientData) => {
    const result = {
        ruleName: 'Điều dường không được chỉ định thuốc',
        ruleId: 'Rule_Id_37',
        isValid: true,
        validateField: 'Chucdanh_id',
        validateFile:'XML2',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml2_data = patientData.Xml2 || [];
        xml2_data.forEach(item => {
            if (item.Chucdanh_id === 7232 || item.Chucdanh_id === 7362) {
                result.errors.push({
                    Id: item.id || item.Id,
                    Error: 'Điều dưỡng không được chỉ định thuốc'
                });
                result.isValid = false;
            }
        });
     

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Điều dường không được chỉ định thuốc: ${error.message}`);
        result.message = 'Lỗi khi validate Điều dường không được chỉ định thuốc';
    }

    return result;
};

module.exports = validateRule_Id_37;

