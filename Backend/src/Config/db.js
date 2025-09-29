const mongoose = require('mongoose');
const LogService = require('../Services/LogService');
require('dotenv').config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/GiamDinhBHYT';

async function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function connectDB() {
    let attempt = 0;
    while (true) {
        try {
            await mongoose.connect(MONGO_URI, {
                useNewUrlParser: true,
                useUnifiedTopology: true
            });
            await LogService.success('Database', 'Connected to MongoDB', { uri: MONGO_URI });
            break;
        } catch (error) {
            attempt++;
            const delay = Math.min(5000, 500 * attempt);
            await LogService.error('Database', `MongoDB connect failed (attempt ${attempt}): ${error.message}. Retry in ${delay}ms`, error);
            await sleep(delay);
        }
    }

    mongoose.connection.on('disconnected', async () => {
        await LogService.warn('Database', 'MongoDB disconnected. Trying to reconnect...');
        // trigger reconnect loop
        connectDB().catch(() => {});
    });
}

module.exports = connectDB;