const LogModel = require('../Repos/Models/LogModel');
const Logger = require('../Utils/Logger');
const { v4: uuidv4 } = require('uuid');

class LogService {
    constructor() {
        this.requestId = null;
    }

    /**
     * Set request ID cho session hiện tại
     */
    setRequestId(requestId = null) {
        this.requestId = requestId || uuidv4();
        return this.requestId;
    }

    /**
     * Lấy request ID hiện tại
     */
    getRequestId() {
        return this.requestId;
    }

    /**
     * Tạo log entry
     */
    async createLog(logData) {
        try {
            const log = new LogModel({
                ...logData,
                requestId: this.requestId,
                timestamp: new Date()
            });
            
            // await log.save();
            return log;
        } catch (error) {
            console.error('Lỗi khi tạo log:', error);
            return null;
        }
    }

    /**
     * Log thông tin chung
     */
    async info(service, message, data = null, req = null) {
        const logData = {
            level: 'info',
            service,
            message,
            data,
            ...this.extractRequestInfo(req)
        };
        
        Logger.info(service, message, data);
        return await this.createLog(logData);
    }

    /**
     * Log cảnh báo
     */
    async warn(service, message, data = null, req = null) {
        const logData = {
            level: 'warn',
            service,
            message,
            data,
            ...this.extractRequestInfo(req)
        };
        
        Logger.warn(service, message, data);
        return await this.createLog(logData);
    }

    /**
     * Log lỗi
     */
    async error(service, message, error = null, req = null) {
        const logData = {
            level: 'error',
            service,
            message,
            error: error ? {
                message: error.message,
                stack: error.stack,
                name: error.name
            } : null,
            ...this.extractRequestInfo(req)
        };
        
        Logger.error(service, message, error);
        return await this.createLog(logData);
    }

    /**
     * Log debug
     */
    async debug(service, message, data = null, req = null) {
        const logData = {
            level: 'debug',
            service,
            message,
            data,
            ...this.extractRequestInfo(req)
        };
        
        Logger.debug(service, message, data);
        
        return await this.createLog(logData);
    }

    /**
     * Log thành công
     */
    async success(service, message, data = null, req = null) {
        const logData = {
            level: 'success',
            service,
            message,
            data,
            ...this.extractRequestInfo(req)
        };
        
        Logger.success(service, message, data);
        Logger.info(service, message);
        return await this.createLog(logData);
    }

    /**
     * Log API request
     */
    async logRequest(req, res, next) {
        const startTime = Date.now();
        const requestId = this.setRequestId();
        
        // Log request bắt đầu
        await this.info('API', `Request started: ${req.method} ${req.path}`, {
            method: req.method,
            endpoint: req.path,
            query: req.query,
            body: req.method !== 'GET' ? req.body : undefined
        }, req);

        // Override res.end để log response
        const originalEnd = res.end;
        const logService = this; // Capture this context
        res.end = function(chunk, encoding) {
            const duration = Date.now() - startTime;
            
            // Log response với Logger
            Logger.apiRequest(req.method, req.path, res.statusCode, duration, req.ip);
            
            // Log response vào database
            logService.info('API', `Request completed: ${req.method} ${req.path}`, {
                statusCode: res.statusCode,
                duration: duration
            }, req);

            originalEnd.call(this, chunk, encoding);
        };

        next();
    }

    /**
     * Trích xuất thông tin từ request
     */
    extractRequestInfo(req) {
        if (!req) return {};
        
        return {
            method: req.method,
            endpoint: req.path,
            ip: req.ip || req.connection.remoteAddress,
            userAgent: req.get('User-Agent'),
            userId: req.user ? req.user.id : null
        };
    }

    /**
     * Lấy logs theo điều kiện
     */
    async getLogs(filters = {}, page = 1, limit = 50) {
        try {
            const skip = (page - 1) * limit;
            
            const query = {};
            
            if (filters.level) query.level = filters.level;
            if (filters.service) query.service = filters.service;
            if (filters.requestId) query.requestId = filters.requestId;
            if (filters.startDate || filters.endDate) {
                query.timestamp = {};
                if (filters.startDate) query.timestamp.$gte = new Date(filters.startDate);
                if (filters.endDate) query.timestamp.$lte = new Date(filters.endDate);
            }

            const logs = await LogModel.find(query)
                .sort({ timestamp: -1 })
                .skip(skip)
                .limit(limit)
                .lean();

            const total = await LogModel.countDocuments(query);

            return {
                logs,
                pagination: {
                    page,
                    limit,
                    total,
                    pages: Math.ceil(total / limit)
                }
            };
        } catch (error) {
            console.error('Lỗi khi lấy logs:', error);
            throw error;
        }
    }

    /**
     * Xóa logs cũ (older than days)
     */
    async cleanOldLogs(days = 30) {
        try {
            const cutoffDate = new Date();
            cutoffDate.setDate(cutoffDate.getDate() - days);
            
            const result = await LogModel.deleteMany({
                timestamp: { $lt: cutoffDate }
            });
            
            await this.info('LogService', `Đã xóa ${result.deletedCount} logs cũ hơn ${days} ngày`);
            return result.deletedCount;
        } catch (error) {
            await this.error('LogService', 'Lỗi khi xóa logs cũ', error);
            throw error;
        }
    }

    /**
     * Thống kê logs
     */
    async getLogStats(days = 7) {
        try {
            const startDate = new Date();
            startDate.setDate(startDate.getDate() - days);
            
            const stats = await LogModel.aggregate([
                {
                    $match: {
                        timestamp: { $gte: startDate }
                    }
                },
                {
                    $group: {
                        _id: {
                            level: '$level',
                            service: '$service'
                        },
                        count: { $sum: 1 }
                    }
                },
                {
                    $group: {
                        _id: '$_id.level',
                        services: {
                            $push: {
                                service: '$_id.service',
                                count: '$count'
                            }
                        },
                        total: { $sum: '$count' }
                    }
                }
            ]);

            return stats;
        } catch (error) {
            console.error('Lỗi khi lấy thống kê logs:', error);
            throw error;
        }
    }
}

module.exports = new LogService();
