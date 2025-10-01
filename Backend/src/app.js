const express = require('express');
const cors = require('cors');
const compression = require('compression');
const connectDB = require('./Config/db');
const PatientRoutes = require('./Routes/PatientRoutes');
const ValidateRoutes = require('./Routes/ValidateRoutes');
const TestRoutes = require('./Routes/TestRoutes');
const LogRoutes = require('./Routes/LogRoutes');
const RuleService = require('./Services/RuleService');
const LogService = require('./Services/LogService');
const Logger = require('./Utils/Logger');
const { errorHandler, notFoundHandler } = require('./Middleware/ErrorHandler');
require('dotenv').config();

// Kết nối database
connectDB();

const app = express();

// Middleware
app.use(cors()); // nới cors để WPF (desktop) không bị chặn
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

app.use(compression());

// Logging middleware
app.use(LogService.logRequest.bind(LogService));

// Routes
app.use('/api/patient', PatientRoutes);
app.use('/api/validate', ValidateRoutes);
app.use('/api/test', TestRoutes);
app.use('/api/logs', LogRoutes);

// Root route
app.get('/', (req, res) => {
    res.send('Giam Dinh BHYT API Online!');
});

// Error handling middleware (must be last)
app.use(notFoundHandler);
app.use(errorHandler);

// Khởi động server
const PORT = process.env.PORT || 3000;
app.listen(PORT, async () => {
    Logger.serverStart(PORT, process.env.NODE_ENV || 'development');
    
    // Log server startup
    await LogService.success('Server', `Server khởi động thành công trên port ${PORT}`);
    
    // Load validation rules khi khởi động
    try {
        await RuleService.loadRules();
       
    } catch (error) {
        await LogService.error('Server', 'Lỗi khi load validation rules', error);
    }
});

module.exports = app;
