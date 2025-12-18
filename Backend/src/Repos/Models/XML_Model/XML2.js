const mongoose = require('mongoose');
const { convertDecimal128 } = require('../../../Utils/ConvertDecimal');


const XML2Schema = new mongoose.Schema({
  id:                   { type: Number, required: false },
  Ma_Lk:                { type: String, default: null },
  Stt:                  { type: Number, default: null },
  Ma_Thuoc:             { type: String, default: null },
  Ma_Pp_CheBien:        { type: String, default: null },
  Ma_Cskcb_Thuoc:       { type: String, default: null },
  Ma_Nhom:              { type: Number, default: null },
  Ten_Thuoc:            { type: String, default: null },
  Don_Vi_Tinh:          { type: String, default: null },
  Ham_Luong:            { type: String, default: null },
  Duong_Dung:           { type: String, default: null },
  Dang_Bao_Che:         { type: String, default: null },
  Lieu_Dung:            { type: String, default: null },
  Cach_Dung:            { type: String, default: null },
  So_Dang_Ky:           { type: String, default: null },
  Tt_Thau:              { type: String, default: null },
  Pham_Vi:              { type: Number, default: null },
  Tyle_Tt_Bh:           { type: mongoose.Schema.Types.Decimal128, default: null },
  So_Luong:             { type: mongoose.Schema.Types.Decimal128, default: null },
  Don_Gia:              { type: mongoose.Schema.Types.Decimal128, default: null },
  Thanh_Tien_Bv:        { type: mongoose.Schema.Types.Decimal128, default: null },
  Thanh_Tien_Bh:        { type: mongoose.Schema.Types.Decimal128, default: null },
  T_NguonKhac_Nsnn:     { type: mongoose.Schema.Types.Decimal128, default: null },
  T_NguonKhac_Vtnn:     { type: mongoose.Schema.Types.Decimal128, default: null },
  T_NguonKhac_Vttn:     { type: mongoose.Schema.Types.Decimal128, default: null },
  T_NguonKhac_Cl:       { type: mongoose.Schema.Types.Decimal128, default: null },
  T_NguonKhac:          { type: mongoose.Schema.Types.Decimal128, default: null },
  Muc_Huong:            { type: mongoose.Schema.Types.Decimal128, default: null },
  T_Bntt:               { type: mongoose.Schema.Types.Decimal128, default: null },
  T_Bncct:              { type: mongoose.Schema.Types.Decimal128, default: null },
  T_Bhtt:               { type: mongoose.Schema.Types.Decimal128, default: null },
  Ma_Khoa:              { type: String, default: null },
  Ma_Bac_Si:            { type: String, default: null },
  Ma_Dich_Vu:           { type: String, default: null },
  Ngay_Yl:              { type: String, default: null },
  Ma_Pttt:              { type: Number, default: null },
  Nguon_Ctra:           { type: Number, default: null },
  Vet_Thuong_Tp:        { type: Number, default: null },
  Du_Phong:             { type: String, default: null },
  Ngay_Th_Yl:           { type: String, default: null },
  chucdanh_id:          { type: Number, default: null }
}, {
  timestamps: true,
  strict: false
});

XML2Schema.set('toJSON',{
  transform: (_, ret) => convertDecimal128(ret),
});

XML2Schema.set('toObject', {
  transform: (_, ret) => convertDecimal128(ret),
});

module.exports = mongoose.model('XML2', XML2Schema);
