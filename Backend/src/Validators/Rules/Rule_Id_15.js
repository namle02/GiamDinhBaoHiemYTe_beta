/**
 * Rule 15:Thanh toán dịch vụ kỹ thuật tiêm bắp, tiêm tĩnh mạch, truyền tĩnh mạch, tháo bột các loại, cắt chỉ… trong điều trị ngoại trú, không thanh toán trong điều trị nội trú.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_15 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ kỹ thuật tiêm bắp, tiêm tĩnh mạch, truyền tĩnh mạch, tháo bột các loại, cắt chỉ… trong điều trị ngoại trú, không thanh toán trong điều trị nội trú.',
        ruleId: 'Rule_Id_15',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        const xml1 = Array.isArray(patientData.Xml1) && patientData.Xml1.length > 0 ? patientData.Xml1[0] : {};

        const danhsachdichvudongian = ['13.0053.0594',
            '14.0203.0075',
            '14.0204.0075',
            '15.0302.0075',
            '10.9004.0075_BS',
            '14.0192.0075',
            '14.0291.0212',
            '03.1703.0075',
            '14.0290.0212',     
            '03.2390.0212',
            '10.9004.0075'];

            const hasSimpleService = xml3_data.some(item2 => danhsachdichvudongian.includes(item2.Ma_Dich_Vu));
            const maLk = typeof xml1.Ma_Lk === 'string' ? xml1.Ma_Lk : '';
            if (hasSimpleService && maLk.includes('TN') && maLk.length !== 13) {
                result.isValid = false;
                xml3_data.forEach(item2 => {
                    if (danhsachdichvudongian.includes(item2.Ma_Dich_Vu)) {
                        result.errors.push({ Id: item2.Id, Error: 'Dịch vụ đơn giản chỉ thanh toán ngoại trú; không thanh toán nội trú' });
                    }
                });
            }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ kỹ thuật tiêm bắp, tiêm tĩnh mạch, truyền tĩnh mạch, tháo bột các loại, cắt chỉ… trong điều trị ngoại trú, không thanh toán trong điều trị nội trú.: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ kỹ thuật tiêm bắp, tiêm tĩnh mạch, truyền tĩnh mạch, tháo bột các loại, cắt chỉ… trong điều trị ngoại trú, không thanh toán trong điều trị nội trú.';
    }

    return result;
};

module.exports = validateRule_Id_15;