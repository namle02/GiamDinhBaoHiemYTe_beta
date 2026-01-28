const mongoose = require('mongoose');

const BenhNhanLoiMaMaySchema = new mongoose.Schema({
    Ma_Lk: {
        type: String,
        default: null
    },
    Ma_May: {
        type: String,
        default: null
    },
    ThoiGianThucHien: {
        type: String,
        default: null
    },
    Ma_Dich_Vu: {
        type: String,
        default: null
    }
}, {
    timestamps: true,
    collection: 'benh_nhan_loi_ma_may'
});

// Index để tối ưu hóa truy vấn
BenhNhanLoiMaMaySchema.index({ Ma_Lk: 1 });
BenhNhanLoiMaMaySchema.index({ Ma_May: 1 });
BenhNhanLoiMaMaySchema.index({ ThoiGianThucHien: 1 });

module.exports = mongoose.model('BenhNhanLoiMaMay', BenhNhanLoiMaMaySchema);
