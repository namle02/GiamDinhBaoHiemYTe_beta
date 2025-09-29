const Logger = require('../Utils/Logger');
const LogService = require('../Services/LogService');

/**
 * Error handling middleware
 */
const errorHandler = async (err, req, res, next) => {
    try {
        // Log error
        await LogService.error('ErrorHandler', 'Unhandled error occurred', err, req);
        
        // Log to console with Logger
        Logger.error('ErrorHandler', 'Unhandled error occurred', err);
        
        // Send error response
        res.status(err.status || 500).json({
            success: false,
            message: err.message || 'Lỗi server',
            ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
        });
    } catch (logError) {
        // Fallback logging if LogService fails
        console.error('Error in error handler:', logError);
        console.error('Original error:', err);
        
        res.status(500).json({
            success: false,
            message: 'Lỗi server'
        });
    }
};

/**
 * 404 handler middleware
 */
const notFoundHandler = async (req, res, next) => {
    try {
        await LogService.warn('NotFoundHandler', `Route not found: ${req.method} ${req.path}`, {
            method: req.method,
            path: req.path,
            query: req.query,
            ip: req.ip
        }, req);
        
        res.status(404).json({
            success: false,
            message: `Route ${req.method} ${req.path} không tồn tại`
        });
    } catch (error) {
        console.error('Error in 404 handler:', error);
        res.status(404).json({
            success: false,
            message: 'Route không tồn tại'
        });
    }
};

/**
 * Async error wrapper
 */
const asyncHandler = (fn) => {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
};

module.exports = {
    errorHandler,
    notFoundHandler,
    asyncHandler
};
