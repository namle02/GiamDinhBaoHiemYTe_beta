const LogService = require('../Services/LogService');

class LogController {
    /**
     * Lấy danh sách logs với filter và pagination
     */
    async getLogs(req, res) {
        try {
            const {
                level,
                service,
                requestId,
                startDate,
                endDate,
                page = 1,
                limit = 50
            } = req.query;

            const filters = {
                level,
                service,
                requestId,
                startDate,
                endDate
            };

            const result = await LogService.getLogs(filters, parseInt(page), parseInt(limit));
            
            await LogService.info('LogController', 'Lấy danh sách logs thành công', {
                filters,
                page,
                limit,
                total: result.pagination.total
            }, req);

            res.status(200).json({
                success: true,
                message: 'Lấy logs thành công',
                data: result
            });
        } catch (error) {
            await LogService.error('LogController', 'Lỗi khi lấy logs', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lấy thống kê logs
     */
    async getLogStats(req, res) {
        try {
            const { days = 7 } = req.query;
            
            const stats = await LogService.getLogStats(parseInt(days));
            
            await LogService.info('LogController', 'Lấy thống kê logs thành công', {
                days,
                statsCount: stats.length
            }, req);

            res.status(200).json({
                success: true,
                message: 'Lấy thống kê logs thành công',
                data: {
                    period: `${days} ngày`,
                    stats
                }
            });
        } catch (error) {
            await LogService.error('LogController', 'Lỗi khi lấy thống kê logs', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Xóa logs cũ
     */
    async cleanOldLogs(req, res) {
        try {
            const { days = 30 } = req.body;
            
            const deletedCount = await LogService.cleanOldLogs(parseInt(days));
            
            await LogService.success('LogController', 'Xóa logs cũ thành công', {
                days,
                deletedCount
            }, req);

            res.status(200).json({
                success: true,
                message: 'Xóa logs cũ thành công',
                data: {
                    deletedCount,
                    days
                }
            });
        } catch (error) {
            await LogService.error('LogController', 'Lỗi khi xóa logs cũ', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lấy logs theo request ID
     */
    async getLogsByRequestId(req, res) {
        try {
            const { requestId } = req.params;
            
            const result = await LogService.getLogs({ requestId }, 1, 1000);
            
            await LogService.info('LogController', 'Lấy logs theo request ID thành công', {
                requestId,
                logCount: result.logs.length
            }, req);

            res.status(200).json({
                success: true,
                message: 'Lấy logs theo request ID thành công',
                data: result
            });
        } catch (error) {
            await LogService.error('LogController', 'Lỗi khi lấy logs theo request ID', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Lấy logs theo service
     */
    async getLogsByService(req, res) {
        try {
            const { service } = req.params;
            const { page = 1, limit = 50, level } = req.query;
            
            const filters = { service };
            if (level) filters.level = level;
            
            const result = await LogService.getLogs(filters, parseInt(page), parseInt(limit));
            
            await LogService.info('LogController', 'Lấy logs theo service thành công', {
                service,
                level,
                page,
                limit,
                total: result.pagination.total
            }, req);

            res.status(200).json({
                success: true,
                message: 'Lấy logs theo service thành công',
                data: result
            });
        } catch (error) {
            await LogService.error('LogController', 'Lỗi khi lấy logs theo service', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }

    /**
     * Tạo log thủ công
     */
    async createLog(req, res) {
        try {
            const { level, service, message, data } = req.body;
            
            if (!level || !service || !message) {
                return res.status(400).json({
                    success: false,
                    message: 'Thiếu thông tin bắt buộc: level, service, message'
                });
            }

            let log;
            switch (level) {
                case 'info':
                    log = await LogService.info(service, message, data, req);
                    break;
                case 'warn':
                    log = await LogService.warn(service, message, data, req);
                    break;
                case 'error':
                    log = await LogService.error(service, message, data, req);
                    break;
                case 'debug':
                    log = await LogService.debug(service, message, data, req);
                    break;
                case 'success':
                    log = await LogService.success(service, message, data, req);
                    break;
                default:
                    return res.status(400).json({
                        success: false,
                        message: 'Level không hợp lệ'
                    });
            }

            res.status(201).json({
                success: true,
                message: 'Tạo log thành công',
                data: log
            });
        } catch (error) {
            await LogService.error('LogController', 'Lỗi khi tạo log thủ công', error, req);
            res.status(500).json({
                success: false,
                message: 'Lỗi server',
                error: error.message
            });
        }
    }
}

module.exports = new LogController();
