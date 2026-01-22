/**
 * Rule 17: Thanh toán xét nghiệm AFB hơn 2 lần/ngày không đúng quy định tại Quyết định số 3126/QĐ-BYT
 * @param {Object} patientData - Toàn bộ dữ liệu bệnh nhân
 * @returns {Object} - Kết quả validation
 */

const validateRule_Id_17 = async (patientData) => {
    const result = {
        ruleName: 'Thanh toán xét nghiệm AFB không quá 2 lần/ngày theo Quyết định 3126/QĐ-BYT',
        ruleId: 'Rule_Id_17',
        isValid: true,
        validateField: 'Ma_Dich_Vu',
        validateFile:'XML3',
        message: '',
        errors: [],
        warnings: []
    };

    try {
        const xml3_data = patientData.Xml3 || [];
        const maDichVuAFB = '24.0017.1714';

        // Nhóm các dịch vụ AFB theo từng ngày y lệnh
        const afbByNgayYl = {};

        for (const item of xml3_data) {
            if (item.Ma_Dich_Vu == maDichVuAFB) {
                // Ngay_Yl có dạng 202501210722, chỉ lấy 8 ký tự đầu (yyyyMMdd)
                let ngayYl = item.Ngay_Yl ? item.Ngay_Yl.toString().substring(0, 8) : 'unknown';
                if (!afbByNgayYl[ngayYl]) {
                    afbByNgayYl[ngayYl] = [];
                }
                afbByNgayYl[ngayYl].push(item);
            }
        }

        // Sắp xếp các dịch vụ trong mỗi ngày theo Ngay_Yl (thứ tự thời gian)
        for (const ngay in afbByNgayYl) {
            afbByNgayYl[ngay].sort((a, b) => {
                const ngayA = a.Ngay_Yl || '';
                const ngayB = b.Ngay_Yl || '';
                return ngayA.localeCompare(ngayB);
            });
        }

        // Kiểm tra từng ngày
        const itemsViPham = [];

        for (const [ngay, items] of Object.entries(afbByNgayYl)) {
            if (items.length <= 2) {
                // Nếu <= 2 lần thì OK, không cần kiểm tra
                continue;
            }

            // Lấy 2 lần đầu tiên
            const firstTwo = items.slice(0, 2);
            const loaiBenhPhamFirstTwo = [
                firstTwo[0].loaiBenhPham_Id || firstTwo[0].LoaiBenhPham_Id,
                firstTwo[1].loaiBenhPham_Id || firstTwo[1].LoaiBenhPham_Id
            ];

            // Đếm số lần xuất hiện của mỗi loại bệnh phẩm
            const countByLoaiBenhPham = {};
            for (const item of items) {
                const loaiBenhPham = (item.loaiBenhPham_Id || item.LoaiBenhPham_Id) || 'null';
                countByLoaiBenhPham[loaiBenhPham] = (countByLoaiBenhPham[loaiBenhPham] || 0) + 1;
            }

            // Kiểm tra từ lần thứ 3 trở đi
            const itemsViPhamInDay = new Set(); // Dùng Set để tránh trùng lặp

            // Điều kiện 1: Lần thứ 3 trở đi phải có loaiBenhPham_Id khác với cả 2 lần đầu
            for (let i = 2; i < items.length; i++) {
                const item = items[i];
                const loaiBenhPham = item.loaiBenhPham_Id || item.LoaiBenhPham_Id;

                if (loaiBenhPhamFirstTwo.includes(loaiBenhPham)) {
                    itemsViPhamInDay.add(item.id || item.Id);
                }
            }

            // Điều kiện 2: Không được có 3 lần nào cùng loaiBenhPham_Id
            for (const [loaiBenhPham, count] of Object.entries(countByLoaiBenhPham)) {
                if (count >= 3) {
                    // Tìm tất cả các item có loại bệnh phẩm này và thêm vào lỗi
                    for (const item of items) {
                        const itemLoaiBenhPham = item.loaiBenhPham_Id || item.LoaiBenhPham_Id;
                        if (itemLoaiBenhPham == loaiBenhPham) {
                            itemsViPhamInDay.add(item.id || item.Id);
                        }
                    }
                }
            }

            // Điều kiện 3: Không được có 2 cặp bệnh phẩm (tức là không được có 2 loại bệnh phẩm nào xuất hiện >= 2 lần)
            let countPairs = 0;
            for (const [loaiBenhPham, count] of Object.entries(countByLoaiBenhPham)) {
                if (count >= 2) {
                    countPairs++;
                }
            }
            if (countPairs > 1) {
                // Có nhiều hơn 1 cặp bệnh phẩm, đánh dấu tất cả các item vi phạm
                for (const item of items) {
                    itemsViPhamInDay.add(item.id || item.Id);
                }
            }

            // Thêm các item vi phạm vào danh sách chung
            for (const item of items) {
                if (itemsViPhamInDay.has(item.id || item.Id)) {
                    itemsViPham.push(item);
                }
            }
        }

        // Ghi lỗi cho các item vi phạm
        if (itemsViPham.length > 0) {
            result.isValid = false;
            for (const item of itemsViPham) {
                result.errors.push({ 
                    Id: item.id || item.Id, 
                    Error: 'Xét nghiệm AFB vượt quá 2 lần/ngày theo Quyết định 3126/QĐ-BYT' 
                });
            }
        }

    } catch (error) {
        result.isValid = false;
        result.errors.push(`Lỗi khi kiểm tra số lượng xét nghiệm AFB theo ngày: ${error.message}`);
        result.message = 'Lỗi khi validate số lượng xét nghiệm AFB theo ngày.';
    }

    return result;
};

module.exports = validateRule_Id_17;