/**
 * Rule 8: Thanh toán DV Nội soi có sinh thiết (Nội soi thực quản dạ dày tá tràng, nội soi ổ bụng,...) nhưng không làm xét nghiệm giải phẫu mô bệnh học, điều chỉnh về mức giá của các DV nội soi không sinh thiết
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_8 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán DV Nội soi có sinh thiết (Nội soi thực quản dạ dày tá tràng, nội soi ổ bụng,...) nhưng không làm xét nghiệm giải phẫu mô bệnh học, điều chỉnh về mức giá của các DV nội soi không sinh thiết',
        ruleId: 'Rule_Id_8',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];
        
        // Danh sách các dịch vụ cần kiểm tra
        const dsDichVuBatBuocPhaiKiemTra = [
            '02.0304.0134',
            '02.0307.0136',
            '02.0309.0138',
            '02.0293.0138',
            '02.0311.0139',
            '02.0262.0136',
            '03.0161.0136'
        ];

        // Kiểm tra xem có dịch vụ nào có đầu 25.xxxx.xxxx không (giải phẫu mô bệnh học)
        const coDichVuDau25 = xml3_data.some(item => 
            item.Ma_Dich_Vu && /^25\.\d{4}\.\d{4}$/.test(item.Ma_Dich_Vu)
        );

        // Tìm các dịch vụ nội soi có sinh thiết trong danh sách
        // Nếu có dịch vụ này mà không có dịch vụ đầu 25 thì kiểm tra PhuTang
        xml3_data.forEach(item => {
            if (item.Ma_Dich_Vu && dsDichVuBatBuocPhaiKiemTra.includes(item.Ma_Dich_Vu) && !coDichVuDau25) {
                // Kiểm tra PhuTang: nếu null/undefined thì sai, nếu không null thì đúng
                const phuTang = item.PhuTang;
                const isPhuTangNull = phuTang === null || phuTang === undefined || 
                    (typeof phuTang === 'string' && phuTang.trim() === '');
                
                if (isPhuTangNull) {
                    result.isValid = false;
                    result.errors.push({
                        Id: item.id || item.Id,
                        Error: `Dịch vụ ${item.Ma_Dich_Vu} nhưng không làm xét nghiệm giải phẫu mô bệnh học, điều chỉnh về mức giá của các DV nội soi không sinh thiết`
                    });
                }
                // Nếu PhuTang không null thì không báo lỗi (đúng)
            }
        });

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán DV Nội soi có sinh thiết (Nội soi thực quản dạ dày tá tràng, nội soi ổ bụng,...) nhưng không làm xét nghiệm giải phẫu mô bệnh học, điều chỉnh về mức giá của các DV nội soi không sinh thiết: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán DV Nội soi có sinh thiết (Nội soi thực quản dạ dày tá tràng, nội soi ổ bụng,...) nhưng không làm xét nghiệm giải phẫu mô bệnh học, điều chỉnh về mức giá của các DV nội soi không sinh thiết';
    }

    return result;
};

module.exports = validateRule_Id_8;