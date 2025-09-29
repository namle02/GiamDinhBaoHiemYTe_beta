const mongoose = require('mongoose');

const LogSchema = new mongoose.Schema({
    level: {
        type: String,
        required: true,
        enum: ['info', 'warn', 'error', 'debug', 'success']
    },
    message: {
        type: String,
        required: true
    },
    service: {
        type: String,
        required: true
    },
    method: {
        type: String,
        required: false
    },
    endpoint: {
        type: String,
        required: false
    },
    userId: {
        type: String,
        required: false
    },
    requestId: {
        type: String,
        required: false
    },
    data: {
        type: mongoose.Schema.Types.Mixed,
        required: false
    },
    error: {
        type: mongoose.Schema.Types.Mixed,
        required: false
    },
    ip: {
        type: String,
        required: false
    },
    userAgent: {
        type: String,
        required: false
    },
    timestamp: {
        type: Date,
        default: Date.now
    },
    duration: {
        type: Number,
        required: false
    }
}, {
    timestamps: true
});

// Index để tối ưu query
LogSchema.index({ timestamp: -1 });
LogSchema.index({ level: 1 });
LogSchema.index({ service: 1 });
LogSchema.index({ requestId: 1 });

module.exports = mongoose.model('Log', LogSchema);
