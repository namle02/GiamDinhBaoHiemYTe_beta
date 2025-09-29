const chalk = require('chalk');

const LoggerConfig = {
    // Log levels và thứ tự ưu tiên
    levels: {
        ERROR: 0,
        WARN: 1,
        INFO: 2,
        DEBUG: 3,
        SUCCESS: 4
    },
    
    // Màu sắc cho từng level
    colors: {
        ERROR: chalk.red.bold,
        WARN: chalk.yellow.bold,
        INFO: chalk.blue.bold,
        DEBUG: chalk.gray.bold,
        SUCCESS: chalk.green.bold,
        TIMESTAMP: chalk.gray,
        SERVICE: chalk.cyan.bold,
        MESSAGE: chalk.white,
        DATA: chalk.magenta
    },
    
    // Màu sắc cho HTTP methods
    methodColors: {
        GET: chalk.green.bold,
        POST: chalk.blue.bold,
        PUT: chalk.yellow.bold,
        DELETE: chalk.red.bold,
        PATCH: chalk.magenta.bold,
        HEAD: chalk.cyan.bold,
        OPTIONS: chalk.gray.bold
    },
    
    // Màu sắc cho HTTP status codes
    statusColors: {
        // 2xx Success
        200: chalk.green.bold,
        201: chalk.green.bold,
        202: chalk.green.bold,
        204: chalk.green.bold,
        
        // 3xx Redirection
        301: chalk.yellow.bold,
        302: chalk.yellow.bold,
        304: chalk.yellow.bold,
        
        // 4xx Client Error
        400: chalk.red.bold,
        401: chalk.red.bold,
        403: chalk.red.bold,
        404: chalk.red.bold,
        422: chalk.red.bold,
        
        // 5xx Server Error
        500: chalk.red.bold.bgRed,
        502: chalk.red.bold.bgRed,
        503: chalk.red.bold.bgRed,
        504: chalk.red.bold.bgRed
    },
    
    // Format cho timestamp
    timestampFormat: 'HH:mm:ss.SSS',
    
    // Separator characters
    separators: {
        line: '=',
        dash: '-',
        dot: '.',
        star: '*'
    },
    
    // Default settings
    defaults: {
        level: 'INFO',
        showTimestamp: true,
        showService: true,
        showData: true,
        maxDataLength: 1000,
        tableMaxWidth: 80
    },
    
    // Environment-specific settings
    environments: {
        development: {
            level: 'DEBUG',
            showTimestamp: true,
            showService: true,
            showData: true,
            colors: true
        },
        production: {
            level: 'INFO',
            showTimestamp: true,
            showService: true,
            showData: false,
            colors: false
        },
        test: {
            level: 'ERROR',
            showTimestamp: false,
            showService: false,
            showData: false,
            colors: false
        }
    },
    
    // Service-specific colors
    serviceColors: {
        'Server': chalk.bold.cyan,
        'Database': chalk.bold.magenta,
        'API': chalk.bold.blue,
        'PatientController': chalk.bold.green,
        'ValidateController': chalk.bold.yellow,
        'LogController': chalk.bold.red,
        'RuleService': chalk.bold.cyan,
        'LogService': chalk.bold.magenta,
        'PatientServices': chalk.bold.blue
    },
    
    // Special formatting
    special: {
        // Database operations
        dbOperations: {
            'INSERT': chalk.green,
            'UPDATE': chalk.yellow,
            'DELETE': chalk.red,
            'SELECT': chalk.blue,
            'CREATE': chalk.green,
            'DROP': chalk.red
        },
        
        // Validation results
        validationResults: {
            'PASS': chalk.green.bold,
            'FAIL': chalk.red.bold,
            'WARN': chalk.yellow.bold
        },
        
        // Server status
        serverStatus: {
            'started': chalk.green.bold,
            'stopped': chalk.red.bold,
            'restarting': chalk.yellow.bold,
            'error': chalk.red.bold
        }
    }
};

module.exports = LoggerConfig;