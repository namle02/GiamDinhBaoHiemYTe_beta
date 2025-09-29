const mongoose = require('mongoose');

const XML9Schema = new mongoose.Schema({
  id:                 { type: Number, required: false },
  Ma_Lk:              { type: String, default: null },
  Ma_Bhxh_Nnd:        { type: String, default: null },
  Ma_The_Nnd:         { type: String, default: null },
  Ho_Ten_Nnd:         { type: String, default: null },
  Ngaysinh_Nnd:       { type: String, default: null },
  Ma_DanToc_Nnd:      { type: String, default: null },
  So_Cccd_Nnd:        { type: String, default: null },
  Ngaycap_Cccd_Nnd:   { type: String, default: null },
  Noicap_Cccd_Nnd:    { type: String, default: null },
  Noi_Cu_Tru_Nnd:     { type: String, default: null },
  Ma_QuocTich:        { type: String, default: null },
  Matinh_Cu_Tru:      { type: String, default: null },
  Mahuyen_Cu_Tru:     { type: String, default: null },
  Maxa_Cu_Tru:        { type: String, default: null },
  Ho_Ten_Cha:         { type: String, default: null },
  Ma_The_Tam:         { type: String, default: null },
  Ho_Ten_Con:         { type: String, default: null },
  Gioi_Tinh_Con:      { type: Number, default: null },
  So_Con:             { type: Number, default: null },
  Lan_Sinh:           { type: Number, default: null },
  So_Con_Song:        { type: Number, default: null },
  Can_Nang_Con:       { type: Number, default: null },
  Ngay_Sinh_Con:      { type: String, default: null },
  Noi_Sinh_Con:       { type: String, default: null },
  Tinh_Trang_Con:     { type: String, default: null },
  Sinhcon_PhauThuat:  { type: Number, default: null },
  Sinhcon_Duoi32Tuan: { type: Number, default: null },
  Ghi_Chu:            { type: String, default: null },
  Nguoi_Do_De:        { type: String, default: null },
  Nguoi_Ghi_Phieu:    { type: String, default: null },
  Ngay_Ct:            { type: String, default: null },
  So:                 { type: String, default: null },
  Quyen_So:           { type: String, default: null },
  Ma_Ttdv:            { type: String, default: null },
  Du_Phong:           { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML9', XML9Schema);
