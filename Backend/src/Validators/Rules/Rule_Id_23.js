/**
 * Rule 23: Thanh toán xét nghiệm “Hồng cầu lưới” đồng thời xét nghiệm “Huyết đồ” do kết quả của xét nghiệm “Huyết đồ” đã có chỉ số “Hồng cầu lưới”.
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_23 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán xét nghiệm “Hồng cầu lưới” đồng thời xét nghiệm “Huyết đồ” do kết quả của xét nghiệm “Huyết đồ” đã có chỉ số “Hồng cầu lưới”.',
        ruleId: 'Rule_Id_23',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        const coHongCauLuoi = xml3_data.some(it => it.Ma_Dich_Vu === '22.0605.1299');
        const coHuyetDo = xml3_data.some(it => it.Ma_Dich_Vu === '22.0134.1296');
        if (coHongCauLuoi && coHuyetDo) {
            result.isValid = false;
            xml3_data.forEach(it => {
                if (it.Ma_Dich_Vu === '22.0605.1299' || it.Ma_Dich_Vu === '22.0134.1296') {
                    result.errors.push({ Id: it.Id, Error: 'Không thanh toán đồng thời xét nghiệm Hồng cầu lưới và Huyết đồ' });
                }
            });
        }
      
    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán xét nghiệm “Hồng cầu lưới” đồng thời xét nghiệm “Huyết đồ” do kết quả của xét nghiệm “Huyết đồ” đã có chỉ số “Hồng cầu lưới”.: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán xét nghiệm “Hồng cầu lưới” đồng thời xét nghiệm “Huyết đồ” do kết quả của xét nghiệm “Huyết đồ” đã có chỉ số “Hồng cầu lưới”.';
    }

    return result;
};

module.exports = validateRule_Id_23;