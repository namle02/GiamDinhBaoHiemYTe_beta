const mongoose = require('mongoose');

const XML13Schema = new mongoose.Schema({
  id:                  { type: Number, required: false },
  Ma_Lk:               { type: String, default: null },
  So_HoSo:             { type: String, default: null },
  So_ChuyenTuyen:      { type: String, default: null },
  Giay_Chuyen_Tuyen:   { type: String, default: null },
  Ma_Cskcb:            { type: String, default: null },
  Ma_Noi_Di:           { type: String, default: null },
  Ma_Noi_Den:          { type: String, default: null },
  Ho_Ten:              { type: String, default: null },
  Ngay_Sinh:           { type: String, default: null },
  Gioi_Tinh:           { type: Number, default: null },
  Ma_QuocTich:         { type: String, default: null },
  Ma_DanToc:           { type: String, default: null },
  Ma_Nghe_Nghiep:      { type: String, default: null },
  Dia_Chi:             { type: String, default: null },
  Ma_The_Bhyt:         { type: String, default: null },
  Gt_The_Den:          { type: String, default: null },
  Ngay_Vao:            { type: String, default: null },
  Ngay_Vao_Noi_Tru:    { type: String, default: null },
  Ngay_Ra:             { type: String, default: null },
  Dau_Hieu_Ls:         { type: String, default: null },
  Chan_DoAn_Rv:        { type: String, default: null },
  Qt_Benhly:           { type: String, default: null },
  Tomtat_Kq:           { type: String, default: null },
  Pp_DieuTri:          { type: String, default: null },
  Ma_Benh_Chinh:       { type: String, default: null },
  Ma_Benh_Kt:          { type: String, default: null },
  Ma_Benh_Yhct:        { type: String, default: null },
  Ten_Dich_Vu:         { type: String, default: null },
  Ten_Thuoc:           { type: String, default: null },
  Pp_Dieu_Tri:         { type: String, default: null },
  Ma_Loai_Rv:          { type: Number, default: null },
  Ma_Lydo_Ct:          { type: Number, default: null },
  Huong_Dieu_Tri:      { type: String, default: null },
  PhuongTien_Vc:       { type: String, default: null },
  Hoten_Nguoi_Ht:      { type: String, default: null },
  Chucdanh_Nguoi_Ht:   { type: String, default: null },
  Ma_Bac_Si:           { type: String, default: null },
  Ma_Ttdv:             { type: String, default: null },
  Du_Phong:            { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML13', XML13Schema);
