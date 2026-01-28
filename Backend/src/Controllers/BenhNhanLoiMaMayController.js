const LogService = require('../Services/LogService');
const BenhNhanLoiMaMayModel = require('../Repos/Models/BenhNhanLoiMaMay');

class BenhNhanLoiMaMayController {
    /**
     * Lấy danh sách bệnh nhân lỗi mã máy
     * Lưu ý: Dữ liệu này được lấy từ SQL Server trong WPF, Backend chỉ lưu trữ trong MongoDB
     */
    async getDsBenhNhanLoiMaMay(req, res) {
        try {
            await LogService.info('BenhNhanLoiMaMayController', 'Lấy danh sách bệnh nhân lỗi mã máy', {}, req);
            
            const results = await BenhNhanLoiMaMayModel.find({})
                .sort({ Ma_May: 1, ThoiGianThucHien: -1 })
                .lean();
            
            await LogService.success('BenhNhanLoiMaMayController', 'Lấy danh sách bệnh nhân lỗi mã máy thành công', {
                count: results.length
            }, req);
            
            res.status(200).json({
                success: true,
                message: 'Lấy danh sách bệnh nhân lỗi mã máy thành công',
                data: results
            });
        } catch (error) {
            await LogService.error('BenhNhanLoiMaMayController', 'Lỗi khi lấy danh sách bệnh nhân lỗi mã máy', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lưu danh sách bệnh nhân lỗi mã máy vào MongoDB
     * Được gọi từ WPF sau khi query từ SQL Server
     */
    async saveDsBenhNhanLoiMaMay(req, res) {
        try {
            const data = req.body;
            
            if (!Array.isArray(data)) {
                return res.status(400).json({
                    success: false,
                    message: 'Dữ liệu phải là mảng'
                });
            }

            await LogService.info('BenhNhanLoiMaMayController', 'Lưu danh sách bệnh nhân lỗi mã máy', {
                count: data.length
            }, req);

            // Xóa dữ liệu cũ và insert dữ liệu mới
            await BenhNhanLoiMaMayModel.deleteMany({});
            const results = await BenhNhanLoiMaMayModel.insertMany(data);

            await LogService.success('BenhNhanLoiMaMayController', 'Lưu danh sách bệnh nhân lỗi mã máy thành công', {
                count: results.length
            }, req);

            res.status(200).json({
                success: true,
                message: 'Lưu danh sách bệnh nhân lỗi mã máy thành công',
                data: {
                    count: results.length
                }
            });
        } catch (error) {
            await LogService.error('BenhNhanLoiMaMayController', 'Lỗi khi lưu danh sách bệnh nhân lỗi mã máy', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }
}

module.exports = new BenhNhanLoiMaMayController();
