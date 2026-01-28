const mongoose = require('mongoose');

const DsBenhNhanLoiMaMaySchema = new mongoose.Schema({
  Ma_Lk:     { type: String, default: null },
  Ma_May:    { type: String, default: null },
  ThoiGian:  { type: String, default: null }
}, { 
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('DsBenhNhanLoiMaMay', DsBenhNhanLoiMaMaySchema);
