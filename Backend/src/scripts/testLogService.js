const LogService = require('../Services/LogService');
const connectDB = require('../Config/db');

async function testLogService() {
    try {
        // Kết nối database
        await connectDB();
        console.log('✅ Đã kết nối database');

        // Test các loại log khác nhau
        console.log('\n🧪 Testing LogService...');

        // Test info log
        await LogService.info('TestService', 'Test info log', { testData: 'info test' });
        console.log('✅ Info log created');

        // Test warn log
        await LogService.warn('TestService', 'Test warning log', { testData: 'warning test' });
        console.log('✅ Warning log created');

        // Test error log
        await LogService.error('TestService', 'Test error log', new Error('Test error message'));
        console.log('✅ Error log created');

        // Test success log
        await LogService.success('TestService', 'Test success log', { testData: 'success test' });
        console.log('✅ Success log created');

        // Test debug log
        await LogService.debug('TestService', 'Test debug log', { testData: 'debug test' });
        console.log('✅ Debug log created');

        // Test lấy logs
        console.log('\n📊 Testing get logs...');
        const logs = await LogService.getLogs({ service: 'TestService' }, 1, 10);
        console.log(`✅ Retrieved ${logs.logs.length} logs`);

        // Test thống kê
        console.log('\n📈 Testing log stats...');
        const stats = await LogService.getLogStats(1);
        console.log(`✅ Retrieved stats:`, stats);

        console.log('\n🎉 All tests completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        process.exit(0);
    }
}

testLogService();
