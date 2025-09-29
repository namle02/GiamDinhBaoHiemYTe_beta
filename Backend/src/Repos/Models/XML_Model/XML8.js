const mongoose = require('mongoose');

const XML8Schema = new mongoose.Schema({
  id:                { type: Number, required: false },
  Ma_Lk:             { type: String, default: null },
  Ma_Loai_Kcb:       { type: String, default: null },
  Ho_Ten_Cha:        { type: String, default: null },
  Ho_Ten_Me:         { type: String, default: null },
  Nguoi_Giam_Ho:     { type: String, default: null },
  Don_Vi:            { type: String, default: null },
  Ngay_Vao:          { type: String, default: null },
  Ngay_Ra:           { type: String, default: null },
  Chan_DoAn_Vao:     { type: String, default: null },
  Chan_DoAn_Rv:      { type: String, default: null },
  Qt_Benhly:         { type: String, default: null },
  Tomtat_Kq:         { type: String, default: null },
  Pp_DieuTri:        { type: String, default: null },
  Ngay_SinhCon:      { type: String, default: null },
  Ngay_ConChet:      { type: String, default: null },
  So_ConChet:        { type: Number, default: null },
  Ket_Qua_Dtri:      { type: Number, default: null },
  Ghi_Chu:           { type: String, default: null },
  Ma_Ttdv:           { type: String, default: null },
  Ngay_Ct:           { type: String, default: null },
  Ma_The_Tam:        { type: String, default: null },
  Du_Phong:          { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML8', XML8Schema);
