/**
 * Rule 55: Thanh toán DVKT "Hút đờm ở BN thở máy" đối với BN không có thở máy
 * Kiểm tra dịch vụ hút đờm phải nằm trong khoảng thời gian thở máy
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_55 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán DVKT "Hút đờm ở BN thở máy" đối với BN không có thở máy',
        ruleId: 'Rule_Id_55',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile: 'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        // Lấy danh sách dịch vụ từ Xml3
        const dsDichVu = Array.isArray(patientData.Xml3) ? patientData.Xml3 : [];

        if (dsDichVu.length === 0) {
            return result;
        }

        // ============================================
        // DANH SÁCH MÃ DỊCH VỤ HÚT ĐỜM
        // ============================================
        const danhSachMaDichVuHutDom = [
            '01.0055.0114',
            '01.0056.0300'
        ];

        // ============================================
        // DANH SÁCH MÃ DỊCH VỤ THỞ MÁY
        // ============================================
        const danhSachMaDichVuThoMay = [
            '01.0129.0209', // Thông khí nhân tạo CPAP qua van Boussignac
            '01.0128.0209', // Thông khí nhân tạo không xâm nhập
            '01.0131.0209', // Thông khí nhân tạo không xâm nhập phương thức BiPAP
            '01.0130.0209', // Thông khí nhân tạo không xâm nhập phương thức CPAP
            '01.0142.0209', // Thông khí nhân tạo kiểu áp lực thể tích với đích thể tích (VCV+ hay MMV+Assure)
            '01.0144.0209', // Thông khí nhân tạo trong khi vận chuyển
            '01.0143.0209', // Thông khí nhân tạo với khí NO
            '01.0132.0209', // Thông khí nhân tạo xâm nhập
            '01.0135.0209', // Thông khí nhân tạo xâm nhập phương thức A/C (VCV)
            '01.0139.0209', // Thông khí nhân tạo xâm nhập phương thức APRV
            '01.0138.0209', // Thông khí nhân tạo xâm nhập phương thức CPAP
            '01.0141.0209', // Thông khí nhân tạo xâm nhập phương thức HFO
            '01.0140.0209', // Thông khí nhân tạo xâm nhập phương thức NAVA
            '01.0134.0209', // Thông khí nhân tạo xâm nhập phương thức PCV
            '01.0137.0209', // Thông khí nhân tạo xâm nhập phương thức PSV
            '01.0136.0209', // Thông khí nhân tạo xâm nhập phương thức SIMV
            '01.0133.0209', // Thông khí nhân tạo xâm nhập phương thức VCV
            '01.0153.0297', // Thở máy xâm nhập hai phổi độc lập
            '03.0058.0209', // Thở máy bằng xâm nhập
            '03.0082.0209', // Thở máy không xâm nhập (thở CPAP, thở BiPAP)
            '03.0054.0297'  // Thở máy với tần số cao (HFO)
        ];

        // Hàm chuyển đổi chuỗi ngày giờ thành Date object
        const parseDateTime = (dateTimeStr) => {
            if (!dateTimeStr) return null;
            
            let str = dateTimeStr.toString().trim();
            
            // Nếu có định dạng yyyyMMddHHmmss
            if (str.length === 14 && /^\d+$/.test(str)) {
                const year = parseInt(str.substring(0, 4));
                const month = parseInt(str.substring(4, 6)) - 1; // Month is 0-indexed
                const day = parseInt(str.substring(6, 8));
                const hour = parseInt(str.substring(8, 10));
                const minute = parseInt(str.substring(10, 12));
                const second = parseInt(str.substring(12, 14));
                return new Date(year, month, day, hour, minute, second);
            }
            
            // Nếu có định dạng yyyyMMddHHmm (12 ký tự)
            if (str.length === 12 && /^\d+$/.test(str)) {
                const year = parseInt(str.substring(0, 4));
                const month = parseInt(str.substring(4, 6)) - 1;
                const day = parseInt(str.substring(6, 8));
                const hour = parseInt(str.substring(8, 10));
                const minute = parseInt(str.substring(10, 12));
                return new Date(year, month, day, hour, minute);
            }
            
            // Nếu có định dạng yyyyMMdd
            if (str.length === 8 && /^\d+$/.test(str)) {
                const year = parseInt(str.substring(0, 4));
                const month = parseInt(str.substring(4, 6)) - 1;
                const day = parseInt(str.substring(6, 8));
                return new Date(year, month, day);
            }
            
            // Nếu có định dạng yyyy-MM-dd HH:mm:ss hoặc yyyy-MM-dd
            if (str.includes('-')) {
                return new Date(str);
            }
            
            return null;
        };

        // Lọc các dịch vụ hút đờm
        const dsDichVuHutDom = dsDichVu.filter(dv => {
            const maDichVu = dv.Ma_Dich_Vu;
            return maDichVu && danhSachMaDichVuHutDom.includes(maDichVu);
        });

        // Lọc các dịch vụ thở máy (có đầy đủ Ngay_Th_Yl và Ngay_kq)
        const dsDichVuThoMay = dsDichVu.filter(dv => {
            const maDichVu = dv.Ma_Dich_Vu;
            const ngayThYL = dv.Ngay_Th_Yl || dv.Ngay_th_YL;
            const ngayKq = dv.Ngay_kq || dv.Ngay_Kq;
            return maDichVu && 
                   danhSachMaDichVuThoMay.includes(maDichVu) && 
                   ngayThYL && 
                   ngayKq;
        });

        // Kiểm tra từng dịch vụ hút đờm
        dsDichVuHutDom.forEach(dvHutDom => {
            const ngayThYLHutDom = dvHutDom.Ngay_Th_Yl || dvHutDom.Ngay_th_YL;
            
            if (!ngayThYLHutDom) {
                result.warnings.push({
                    Id: dvHutDom.id || dvHutDom.Id,
                    Error: `Dịch vụ hút đờm ${dvHutDom.Ma_Dich_Vu} thiếu thông tin Ngay_Th_Yl`
                });
                return;
            }

            const dateHutDom = parseDateTime(ngayThYLHutDom);
            if (!dateHutDom) {
                result.warnings.push({
                    Id: dvHutDom.id || dvHutDom.Id,
                    Error: `Dịch vụ hút đờm ${dvHutDom.Ma_Dich_Vu} có định dạng ngày không hợp lệ: ${ngayThYLHutDom}`
                });
                return;
            }

            // Kiểm tra xem có dịch vụ thở máy nào có khoảng thời gian bao phủ Ngay_Th_Yl của dịch vụ hút đờm không
            const coThoMay = dsDichVuThoMay.some(dvThoMay => {
                const ngayThYLThoMay = dvThoMay.Ngay_Th_Yl || dvThoMay.Ngay_th_YL;
                const ngayKqThoMay = dvThoMay.Ngay_kq || dvThoMay.Ngay_Kq;
                
                const dateThYLThoMay = parseDateTime(ngayThYLThoMay);
                const dateKqThoMay = parseDateTime(ngayKqThoMay);
                
                if (!dateThYLThoMay || !dateKqThoMay) {
                    return false;
                }

                // Kiểm tra: Ngay_Th_Yl của hút đờm phải nằm trong khoảng [Ngay_Th_Yl, Ngay_kq] của thở máy
                return dateHutDom >= dateThYLThoMay && dateHutDom <= dateKqThoMay;
            });

            // Nếu không có dịch vụ thở máy nào bao phủ thì báo lỗi
            if (!coThoMay) {
                result.isValid = false;
                result.errors.push({
                    Id: dvHutDom.id || dvHutDom.Id,
                    Error: `Dịch vụ hút đờm ${dvHutDom.Ma_Dich_Vu} (Ngay_Th_Yl: ${ngayThYLHutDom}) không nằm trong khoảng thời gian thở máy của bệnh nhân`
                });
            }
        });

        if (result.errors.length > 0) {
            result.message = 'Có dịch vụ hút đờm không nằm trong khoảng thời gian thở máy';
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi validate Thanh toán DVKT "Hút đờm ở BN thở máy" đối với BN không có thở máy: ${error.message}`);
        result.message = 'Lỗi khi validate Thanh toán DVKT "Hút đờm ở BN thở máy" đối với BN không có thở máy';
    }

    return result;
};

module.exports = validateRule_Id_55;
