const Logger = require('../Utils/Logger');

function testLogger() {
    console.log('🧪 Testing Logger Utility\n');
    
    // Test các loại logs
    Logger.info('TestService', 'Test info message', { data: 'info test' });
    Logger.warn('TestService', 'Test warning message', { data: 'warning test' });
    Logger.error('TestService', 'Test error message', new Error('Test error'));
    Logger.success('TestService', 'Test success message', { data: 'success test' });
    Logger.debug('TestService', 'Test debug message', { data: 'debug test' });
    
    console.log('\n');
    
    // Test API request logs
    Logger.apiRequest('GET', '/api/patients', 200, 150, '127.0.0.1');
    Logger.apiRequest('POST', '/api/patients', 201, 300, '192.168.1.1');
    Logger.apiRequest('PUT', '/api/patients/123', 200, 200, '10.0.0.1');
    Logger.apiRequest('DELETE', '/api/patients/123', 204, 100, '172.16.0.1');
    Logger.apiRequest('GET', '/api/invalid', 404, 50, '127.0.0.1');
    Logger.apiRequest('POST', '/api/error', 500, 5000, '127.0.0.1');
    
    console.log('\n');
    
    // Test database logs
    Logger.db('INSERT', 'patients', 25, true);
    Logger.db('UPDATE', 'patients', 15, true);
    Logger.db('DELETE', 'patients', 5, true);
    Logger.db('SELECT', 'patients', 10, true);
    Logger.db('INSERT', 'logs', 100, false);
    
    console.log('\n');
    
    // Test server logs
    Logger.serverStart(3000, 'development');
    Logger.serverStart(8080, 'production');
    
    console.log('\n');
    
    // Test validation logs
    Logger.validation('PatientIdRule', true, 5);
    Logger.validation('EmailRule', false, 10);
    Logger.validation('PhoneRule', true, 3);
    Logger.validation('AddressRule', false, 8);
    
    console.log('\n');
    
    // Test table output
    const testData = [
        { name: 'PatientController', requests: 150, errors: 2 },
        { name: 'ValidateController', requests: 80, errors: 0 },
        { name: 'LogController', requests: 25, errors: 1 },
        { name: 'TestController', requests: 5, errors: 0 }
    ];
    
    Logger.info('TestService', 'Controller Statistics:');
    Logger.table(testData);
    
    console.log('\n');
    
    // Test different log levels
    Logger.setLevel('DEBUG');
    Logger.info('TestService', 'This should show (DEBUG level)');
    Logger.debug('TestService', 'This should show (DEBUG level)');
    
    Logger.setLevel('ERROR');
    Logger.info('TestService', 'This should NOT show (ERROR level)');
    Logger.debug('TestService', 'This should NOT show (ERROR level)');
    Logger.error('TestService', 'This should show (ERROR level)');
    
    Logger.setLevel('INFO'); // Reset to default
    
    Logger.success('TestService', 'All Logger tests completed successfully!');
}

testLogger();
