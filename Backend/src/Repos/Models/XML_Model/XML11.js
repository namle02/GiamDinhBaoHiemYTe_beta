const mongoose = require('mongoose');

const XML11Schema = new mongoose.Schema({
  id:                  { type: Number, required: false },
  Ma_Lk:               { type: String, default: null },
  So_Ct:               { type: String, default: null },
  So_Seri:             { type: String, default: null },
  So_Kcb:              { type: String, default: null },
  Don_Vi:              { type: String, default: null },
  Ma_Bhxh:             { type: String, default: null },
  Ma_The_Bhyt:         { type: String, default: null },
  Chan_DoAn_Rv:        { type: String, default: null },
  Pp_DieuTri:          { type: String, default: null },
  Ma_Dinh_Chi_Thai:    { type: Number, default: null },
  NguyenNhan_DinhChi:  { type: String, default: null },
  Tuoi_Thai:           { type: String, default: null },
  So_Ngay_Nghi:        { type: Number, default: null },
  Tu_Ngay:             { type: String, default: null },
  Den_Ngay:            { type: String, default: null },
  Ho_Ten_Cha:          { type: String, default: null },
  Ho_Ten_Me:           { type: String, default: null },
  Ma_Ttdv:             { type: String, default: null },
  Ma_Bs:               { type: String, default: null },
  Ngay_Ct:             { type: String, default: null },
  Ma_The_Tam:          { type: String, default: null },
  Mau_So:              { type: String, default: null },
  Du_Phong:            { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML11', XML11Schema);
