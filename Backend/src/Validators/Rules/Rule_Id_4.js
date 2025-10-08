/**
 * Rule 4: Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ)
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_4 = (patientData) => {
    const result = {
        ruleName: 'Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ)',
        ruleId: 'Rule_Id_4',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        // Lọc ra các dịch vụ có mã 20.0084.0440 và 20.0083.0104
        const ds_0440 = xml3_data.filter(item => item.Ma_Dich_Vu === '20.0084.0440');
        const ds_0104 = xml3_data.filter(item => item.Ma_Dich_Vu === '20.0083.0104');

        // Nếu cả hai loại dịch vụ đều tồn tại
        if (ds_0440.length > 0 && ds_0104.length > 0) {
            // So sánh từng cặp, nếu có mã bệnh trùng nhau thì báo lỗi
            ds_0440.forEach(item0440 => {
                ds_0104.forEach(item0104 => {
                    // Tách mã bệnh thành mảng (dạng E03.8;E78.2;E87.6;J31.2;N64.4)
                    const arrMaBenh0440 = (item0440.Ma_Benh || '').split(';').map(s => s.trim()).filter(Boolean);
                    const arrMaBenh0104 = (item0104.Ma_Benh || '').split(';').map(s => s.trim()).filter(Boolean);

                    // Kiểm tra xem có mã bệnh nào trùng nhau không
                    const trungMaBenh = arrMaBenh0440.some(maBenh => arrMaBenh0104.includes(maBenh) && maBenh);

                    if (trungMaBenh) {
                        result.isValid = false;
                        result.errors.push({
                            Id:item0104.Id,
                            Error: 'Không được thanh toán đồng thời dịch vụ Nội soi tán sỏi niệu quản các loại và Đặt ống thông niệu quản qua nội soi (sond JJ) cho cùng một mã bệnh.'
                        },{
                            Id:item0440.Id,
                            Error: 'Không được thanh toán đồng thời dịch vụ Nội soi tán sỏi niệu quản các loại và Đặt ống thông niệu quản qua nội soi (sond JJ) cho cùng một mã bệnh.'
                        });
                    }
                });
            });
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ): ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán dịch vụ Nội soi tán sỏi niệu quản các loại, không thanh toán thêm Đặt ống thông niệu quản qua nội soi (sond JJ)';
    }

    return result;
};

module.exports = validateRule_Id_4;