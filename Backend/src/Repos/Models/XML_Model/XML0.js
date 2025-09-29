const mongoose = require('mongoose');

const XML0Schema = new mongoose.Schema({
  id:            { type: Number, required: false },  
  Ma_Lk:         { type: String, default: null },
  Stt:           { type: Number, default: null },
  Ma_Bn:         { type: String, default: null },
  Ho_Ten:        { type: String, default: null },
  So_Cccd:       { type: String, default: null },
  Ngay_Sinh:     { type: String, default: null },
  Gioi_Tinh:     { type: Number, default: null },
  Ma_The_Bhyt:   { type: String, default: null },
  Ma_Dkbd:       { type: String, default: null },
  Gt_The_Tu:     { type: String, default: null },
  Gt_The_Den:    { type: String, default: null },
  Ma_DoiTuong_Kcb:{ type: String, default: null },
  Ngay_Vao:      { type: String, default: null },
  Ngay_Vao_Noi_Tru:{ type: String, default: null },
  Ly_Do_Vnt:     { type: String, default: null },
  Ma_Ly_Do_Vnt:  { type: String, default: null },
  Ma_Loai_Kcb:   { type: String, default: null },
  Ma_Cskcb:      { type: String, default: null },
  Ma_Dich_Vu:    { type: String, default: null },
  Ten_Dich_Vu:   { type: String, default: null },
  Ma_Thuoc:      { type: String, default: null },
  Ten_Thuoc:     { type: String, default: null },
  Ma_Vat_Tu:     { type: String, default: null },
  Ten_Vat_Tu:    { type: String, default: null },
  Ngay_Yl:       { type: String, default: null },
  Du_Phong:      { type: String, default: null },
}, { 
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML0', XML0Schema);
