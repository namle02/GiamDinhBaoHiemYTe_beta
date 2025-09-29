const mongoose = require('mongoose');

const XML4Schema = new mongoose.Schema({
  id:             { type: Number, required: false },
  Ma_Lk:          { type: String, default: null },
  Stt:            { type: Number, default: null },
  Ma_Dich_Vu:     { type: String, default: null },
  Ma_Chi_So:      { type: String, default: null },
  Ten_Chi_So:     { type: String, default: null },
  Gia_Tri:        { type: String, default: null },
  Don_Vi_Do:      { type: String, default: null },
  Mo_Ta:          { type: String, default: null },
  Ket_Luan:       { type: String, default: null },
  Ngay_Kq:        { type: String, default: null },
  Ma_Bs_Doc_Kq:   { type: String, default: null },
  Du_Phong:       { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML4', XML4Schema);
