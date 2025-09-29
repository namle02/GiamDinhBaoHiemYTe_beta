const moment = require('moment');

class Logger {
    constructor() {
        this.levels = {
            ERROR: 0,
            WARN: 1,
            INFO: 2,
            DEBUG: 3,
            SUCCESS:41
        };
        
        this.currentLevel = this.levels.INFO;
        this.environment = process.env.NODE_ENV || 'development';
        this.colors = this.environment === 'production' ? false : true;
    }

    /**
     * Set log level
     */
    setLevel(level) {
        this.currentLevel = this.levels[level.toUpperCase()] || this.levels.INFO;
    }

    /**
     * Format timestamp
     */
    formatTimestamp() {
        return `[${moment().format('HH:mm:ss.SSS')}]`;
    }

    /**
     * Format service name
     */
    formatService(service) {
        return `[${service}]`;
    }

    /**
     * Format log level
     */
    formatLevel(level) {
        return `[${level}]`;
    }

    /**
     * Format message
     */
    formatMessage(message) {
        return message;
    }

    /**
     * Format data object
     */
    formatData(data) {
        if (!data) return '';
        return `\n${JSON.stringify(data, null, 2)}`;
    }

    /**
     * Core log method
     */
    log(level, service, message, data = null) {
        const levelNum = this.levels[level];
        if (levelNum > this.currentLevel) return;

        const timestamp = this.formatTimestamp();
        const levelStr = this.formatLevel(level);
        const serviceStr = this.formatService(service);
        const messageStr = this.formatMessage(message);

        console.log(`${timestamp} ${levelStr} ${serviceStr} ${messageStr}`);
    }

    /**
     * Error log
     */
    error(service, message, error = null) {
        const errorData = error ? {
            message: error.message,
            stack: error.stack,
            name: error.name
        } : null;
        
        this.log('ERROR', service, message, errorData);
    }

    /**
     * Warning log
     */
    warn(service, message, data = null) {
        this.log('WARN', service, message, data);
    }

    /**
     * Info log
     */
    info(service, message, data = null) {
        this.log('INFO', service, message, data);
    }

    /**
     * Debug log
     */
    debug(service, message, data = null) {
        
        this.log('DEBUG', service, message, data);
    }

    /**
     * Success log
     */
    success(service, message, data = null) {
        this.log('SUCCESS', service, message, data);
    }

    /**
     * API Request log
     */
    apiRequest(method, endpoint, statusCode, duration, ip = null) {
        const timestamp = this.formatTimestamp();
        const methodStr = `[${method}]`;
        const endpointStr = endpoint;
        const statusStr = `[${statusCode}]`;
        const durationStr = `${duration}ms`;
        const ipStr = ip ? `[${ip}]` : '';

        console.log(`${timestamp} ${methodStr} ${endpointStr} ${statusStr} ${durationStr} ${ipStr}`);
    }

    /**
     * Database operation log
     */
    db(operation, collection, duration, success = true) {
        const timestamp = this.formatTimestamp();
        const operationStr = `[DB]`;
        const collectionStr = `[${collection}]`;
        const operationType = operation;
        const durationStr = `${duration}ms`;
        const statusStr = success ? '✓' : '✗';

        console.log(`${timestamp} ${operationStr} ${collectionStr} ${operationType} ${durationStr} ${statusStr}`);
    }

    /**
     * Server startup log
     */
    serverStart(port, environment = 'development') {
        const timestamp = this.formatTimestamp();
        const serverStr = `[SERVER]`;
        const portStr = `[Port: ${port}]`;
        const envStr = `[${environment}]`;
        const messageStr = 'Server started successfully';

        console.log(`${timestamp} ${serverStr} ${portStr} ${envStr} ${messageStr}`);
    }

    /**
     * Database connection log
     */
    dbConnect(uri, success = true) {
        const timestamp = this.formatTimestamp();
        const dbStr = `[DATABASE]`;
        const statusStr = success ? 'Connected' : 'Connection failed';
        const uriStr = uri;

        console.log(`${timestamp} ${dbStr} ${statusStr} to ${uriStr}`);
    }

    /**
     * Validation log
     */
    validation(ruleName, result, duration = null) {
        const timestamp = this.formatTimestamp();
        const validationStr = `[VALIDATION]`;
        const ruleStr = `[${ruleName}]`;
        const resultStr = result ? 'PASS' : 'FAIL';
        const durationStr = duration ? `${duration}ms` : '';

        console.log(`${timestamp} ${validationStr} ${ruleStr} ${resultStr} ${durationStr}`);
    }

    /**
     * Separator line
     */
    separator(char = '=', length = 50) {
        console.log(char.repeat(length));
    }

    /**
     * Title
     */
    title(text) {
        this.separator();
        console.log(`  ${text}  `);
        this.separator();
    }

    /**
     * Table-like output
     */
    table(data) {
        if (!Array.isArray(data) || data.length === 0) return;
        
        const keys = Object.keys(data[0]);
        const widths = keys.map(key => Math.max(key.length, ...data.map(row => String(row[key] || '').length)));
        
        // Header
        const header = keys.map((key, i) => key.padEnd(widths[i])).join(' | ');
        console.log(header);
        console.log('-'.repeat(header.length));
        
        // Rows
        data.forEach(row => {
            const rowStr = keys.map((key, i) => String(row[key] || '').padEnd(widths[i])).join(' | ');
            console.log(rowStr);
        });
    }
}

module.exports = new Logger();