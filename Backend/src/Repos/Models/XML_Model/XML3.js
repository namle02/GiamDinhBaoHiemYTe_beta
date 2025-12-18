const mongoose = require('mongoose');
const { convertDecimal128 } = require('../../../Utils/ConvertDecimal');

const XML3Schema = new mongoose.Schema({
  id:                  { type: Number, required: false },
  LoaiBenhPham_Id:     { type: String, required: false },
  Ma_Lk:               { type: String, default: null },
  Stt:                 { type: Number, default: null },
  Ma_Dich_Vu:          { type: String, default: null },
  Ma_Pttt_Qt:          { type: String, default: null },
  Ma_Vat_Tu:           { type: String, default: null },
  Ma_Nhom:             { type: Number, default: null },
  Goi_Vtyt:            { type: String, default: null },
  Ten_Vat_Tu:          { type: String, default: null },
  Ten_Dich_Vu:         { type: String, default: null },
  Ma_Xang_Dau:         { type: String, default: null },
  Don_Vi_Tinh:         { type: String, default: null },
  Pham_Vi:             { type: Number, default: null },
  So_Luong:            { type: mongoose.Schema.Types.Decimal128, default: null },
  Don_Gia_Bv:          { type: mongoose.Schema.Types.Decimal128, default: null },
  Don_Gia_Bh:          { type: mongoose.Schema.Types.Decimal128, default: null },
  Tt_Thau:             { type: String, default: null },
  Tyle_Tt_Dv:          { type: mongoose.Schema.Types.Decimal128, default: null },
  Tyle_Tt_Bh:          { type: mongoose.Schema.Types.Decimal128, default: null },
  Thanh_Tien_Bv:       { type: mongoose.Schema.Types.Decimal128, default: null },
  Thanh_Tien_Bh:       { type: mongoose.Schema.Types.Decimal128, default: null },
  T_TranTt:            { type: mongoose.Schema.Types.Decimal128, default: null },
  Muc_Huong:           { type: mongoose.Schema.Types.Decimal128, default: null },
  T_NguonKhac_Nsnn:    { type: mongoose.Schema.Types.Decimal128, default: null },
  T_NguonKhac_Vtnn:    { type: mongoose.Schema.Types.Decimal128, default: null },
  T_NguonKhac_Vttn:    { type: mongoose.Schema.Types.Decimal128, default: null },
  T_NguonKhac_Cl:      { type: mongoose.Schema.Types.Decimal128, default: null },
  T_NguonKhac:         { type: mongoose.Schema.Types.Decimal128, default: null },
  T_Bntt:              { type: mongoose.Schema.Types.Decimal128, default: null },
  T_Bncct:             { type: mongoose.Schema.Types.Decimal128, default: null },
  T_Bhtt:              { type: mongoose.Schema.Types.Decimal128, default: null },
  Ma_Khoa:             { type: String, default: null },
  Ma_Giuong:           { type: String, default: null },
  Ma_Bac_Si:           { type: String, default: null },
  Mo_Ta_Text:          { type: String, default: null },
  Nguoi_Thuc_Hien:     { type: String, default: null },
  Ma_Benh:             { type: String, default: null },
  Ma_Benh_Yhct:        { type: String, default: null },
  Ngay_Yl:             { type: String, default: null },
  Ngay_Th_Yl:          { type: String, default: null },
  Ngay_Kq:             { type: String, default: null },
  Ma_Pttt:             { type: Number, default: null },
  Vet_Thuong_Tp:       { type: Number, default: null },
  Pp_Vo_Cam:           { type: Number, default: null },
  Vi_Tri_Th_Dvkt:      { type: Number, default: null },
  Ma_May:              { type: String, default: null },
  Ma_Hieu_Sp:          { type: String, default: null },
  trinhTuThucHien:     { type: String, default: null },
  Tai_Su_Dung:         { type: String, default: null },
  Du_Phong:            { type: String, default: null },
  chucdanh_id:         { type: Number, default: null },
  ketQua:              { type: String, default: null },
  mucBinhThuong:       { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

XML3Schema.set('toJSON',{
  transform: (_, ret) => convertDecimal128(ret),
});

XML3Schema.set('toObject', {
  transform: (_, ret) => convertDecimal128(ret),
});

module.exports = mongoose.model('XML3', XML3Schema);
