const mongoose = require('mongoose');

const doctorSchema = new mongoose.Schema({
    STT: {
        type: Number,
        required: true
    },
    MA_LOAI_KCB: {
        type: Number,
        required: true
    },
    MA_KHOA: {
        type: [String],
        required: true,
        // Dữ liệu có dạng: K27.2;13.27.1;13.27.2
        validate: {
            validator: function (v) {
                return Array.isArray(v) 
            },
            message: 'MA_KHOA phải là mảng các chuỗi'
        }
    },
    TEN_KHOA: {
        type: String,
        required: true,
        trim: true
    },
    MA_BHXH: {
        type: Number,
        required: true
    },
    HO_TEN: {
        type: String,
        required: true,
        trim: true
    },
    GIOI_TINH: {
        type: Number,
        required: true,
        enum: [1,2], // 1: Nam, 2: Nữ
        validate: {
            validator: function (v) {
                return v === 1   || v === 2;
            },
            message: 'GIOI_TINH phải là 1 (Nam) hoặc 2 (Nữ)'
        }
    },
    CHUCDANH_NN: {
        type: Number,
        required: true
    },
    VI_TRI: {
        type: Number,
        required: false
    },
    MACCHN: {
        type: String,
        required: true,
        trim: true
    },
    NGAYCAP_CCHN: {
        type: Date,
        required: true,
        // Dữ liệu có dạng: 7/2/2014 0:00
        validate: {
            validator: function (v) {
                return v instanceof Date && !isNaN(v);
            },
            message: 'NGAYCAP_CCHN phải là ngày hợp lệ'
        }
    },
    NOICAP_CCHN: {
        type: String,
        required: true,
        trim: true
    },
    PHAMVI_CM: {
        type: [Number],
        required: true,
        // Dữ liệu có dạng: 116;128
        validate: {
            validator: function (v) {
                return Array.isArray(v) && v.every(item => typeof item === 'number');
            },
            message: 'PHAMVI_CM phải là mảng các số'
        }
    },
    PHAMVI_CMBS: {
        type: Number,
        required: false // Có thể null
    },
    DVKT_KHAC: {
        type: [String],
        required: false,
        // Dữ liệu có dạng: 01.0176;01.0185;01.0178;...
        validate: {
            validator: function (v) {
                return Array.isArray(v) 
            },
            message: 'DVKT_KHAC phải là mảng các chuỗi có định dạng XX.XXXX'
        }
    },
    VB_PHANCONG: {
        type: Number,
        required: false // Có thể null
    },
    THOIGIAN_DK: {
        type: Number,
        required: true
    },
    THOIGIAN_NGAY: {
        type: String,
        required: true,
        // Dữ liệu có dạng: 0700-1630
        validate: {
            validator: function (v) {
                return /^\d{4}-\d{4}$/.test(v);
            },
            message: 'THOIGIAN_NGAY phải có định dạng HHMM-HHMM (VD: 0700-1630)'
        }
    },
    THOIGIAN_TUAN: {
        type: String,
        required: true
    },
    CSKCB_KHAC: {
        type: String,
        required: false, // Có thể null
        trim: true
    },
    CSKCB_CGKT: {
        type: String,
        required: false, // Có thể null
        trim: true
    },
    QD_CGKT: {
        type: String,
        required: false, // Có thể null
        trim: true
    },
    TU_NGAY: {
        type: Date,
        required: true,
        // Dữ liệu có dạng: 20150106
        validate: {
            validator: function (v) {
                return v instanceof Date && !isNaN(v);
            },
            message: 'TU_NGAY phải là ngày hợp lệ'
        }
    },
    DEN_NGAY: {
        type: Date,
        required: false, // Có thể null
        validate: {
            validator: function (v) {
                return v === null || (v instanceof Date && !isNaN(v));
            },
            message: 'DEN_NGAY phải là ngày hợp lệ hoặc null'
        }
    },
    ID: {
        type: Number,
        required: true,
        unique: true
    }
}, {
    timestamps: true, // Tự động thêm createdAt và updatedAt
    collection: 'doctors' // Tên collection trong MongoDB
});

// Index để tối ưu hóa truy vấn
doctorSchema.index({ ID: 1 });
doctorSchema.index({ MA_BHXH: 1 });
doctorSchema.index({ MACCHN: 1 });
doctorSchema.index({ HO_TEN: 1 });

// Middleware để xử lý dữ liệu trước khi lưu
doctorSchema.pre('save', function (next) {
    // Xử lý MA_KHOA từ string sang array nếu cần
    if (typeof this.MA_KHOA === 'string' && this.MA_KHOA.includes(';')) {
        // Giữ nguyên dạng string như yêu cầu
    }

    // Xử lý PHAMVI_CM từ string sang array nếu cần
    if (typeof this.PHAMVI_CM === 'string' && this.PHAMVI_CM.includes(';')) {
        this.PHAMVI_CM = this.PHAMVI_CM.split(';').map(item => parseInt(item.trim()));
    }

    // Xử lý DVKT_KHAC từ string sang array nếu cần
    if (typeof this.DVKT_KHAC === 'string' && this.DVKT_KHAC.includes(';')) {
        this.DVKT_KHAC = this.DVKT_KHAC.split(';').map(item => item.trim());
    }

    next();
});

// Static methods
doctorSchema.statics.findByMaBHXH = function (maBHXH) {
    return this.findOne({ MA_BHXH: maBHXH });
};

doctorSchema.statics.findByMaCCHN = function (maCCHN) {
    return this.findOne({ MACCHN: maCCHN });
};

doctorSchema.statics.findByKhoa = function (maKhoa) {
    return this.find({ MA_KHOA: { $regex: maKhoa, $options: 'i' } });
};

// Instance methods
doctorSchema.methods.getFullName = function () {
    return this.HO_TEN;
};

doctorSchema.methods.isActive = function () {
    const now = new Date();
    return this.TU_NGAY <= now && (this.DEN_NGAY === null || this.DEN_NGAY >= now);
};

const Doctor = mongoose.model('Doctor', doctorSchema);

module.exports = Doctor;