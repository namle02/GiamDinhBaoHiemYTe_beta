const mongoose = require('mongoose');

const XML7Schema = new mongoose.Schema({
  id:                    { type: Number, required: false },
  Ma_Lk:                 { type: String, default: null },
  So_Luu_Tru:            { type: String, default: null },
  Ma_Yte:                { type: String, default: null },
  Ma_Khoa_Rv:            { type: String, default: null },
  Ngay_Vao:              { type: String, default: null },
  Ngay_Ra:               { type: String, default: null },
  Ma_Dinh_Chi_Thai:      { type: Number, default: null },
  NguyenNhan_DinhChi:    { type: String, default: null },
  ThoiGian_DinhChi:      { type: String, default: null },
  Tuoi_Thai:             { type: String, default: null },
  Chan_DoAn_Rv:          { type: String, default: null },
  Pp_DieuTri:            { type: String, default: null },
  Ghi_Chu:               { type: String, default: null },
  Ma_Ttdv:               { type: String, default: null },
  Ma_Bs:                 { type: String, default: null },
  Ten_Bs:                { type: String, default: null },
  Ngay_Ct:               { type: String, default: null },
  Ma_Cha:                { type: String, default: null },
  Ma_Me:                 { type: String, default: null },
  Ma_The_Tam:            { type: String, default: null },
  Ho_Ten_Cha:            { type: String, default: null },
  Ho_Ten_Me:             { type: String, default: null },
  So_Ngay_Nghi:          { type: Number, default: null },
  NgoaiTru_TuNgay:       { type: String, default: null },
  NgoaiTru_DenNgay:      { type: String, default: null },
  Du_Phong:              { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML7', XML7Schema);
