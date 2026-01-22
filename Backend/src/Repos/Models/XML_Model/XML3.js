const mongoose = require('mongoose');
const { convertDecimal128 } = require('../../../Utils/ConvertDecimal');

const XML3Schema = new mongoose.Schema({
  Id:                  { type: Number, required: false },
  loaiBenhPham_Id:     { type: String, required: false },
  LoaiBenhPham_Id:     { type: String, required: false }, // Thêm field PascalCase để nhận từ WPF
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
  moTa_Text:           { type: String, default: null },
  MoTa_Text:           { type: String, default: null }, // Thêm field PascalCase để nhận từ WPF
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
  ket_luan:             { type: String, default: null },
  ketluan:              { type: String, default: null }, // Thêm field để nhận từ WPF
  Tai_Su_Dung:         { type: String, default: null },
  Du_Phong:            { type: String, default: null },
  chucdanh_id:         { type: Number, default: null }
}, {
  timestamps: true,
  strict: false
});

// Pre-save hook để normalize các field PascalCase -> camelCase khi lưu vào DB
XML3Schema.pre('save', function(next) {
  // Normalize TrinhTuThucHien -> trinhTuThucHien
  if (this.TrinhTuThucHien && !this.trinhTuThucHien) {
    this.trinhTuThucHien = this.TrinhTuThucHien;
  }
  // Normalize MoTa_Text -> moTa_Text
  if (this.MoTa_Text && !this.moTa_Text) {
    this.moTa_Text = this.MoTa_Text;
  }
  // Normalize LoaiBenhPham_Id -> loaiBenhPham_Id
  if (this.LoaiBenhPham_Id && !this.loaiBenhPham_Id) {
    this.loaiBenhPham_Id = this.LoaiBenhPham_Id;
  }
  // Normalize ketluan -> ket_luan (chuẩn hóa từ WPF)
  if (this.ketluan && !this.ket_luan) {
    this.ket_luan = this.ketluan;
  }
  next();
});

// Transform để normalize các field PascalCase -> camelCase khi output
const normalizeTransform = (doc, ret) => {
  // Normalize TrinhTuThucHien -> trinhTuThucHien
  if (ret.TrinhTuThucHien && !ret.trinhTuThucHien) {
    ret.trinhTuThucHien = ret.TrinhTuThucHien;
  }
  // Normalize MoTa_Text -> moTa_Text
  if (ret.MoTa_Text && !ret.moTa_Text) {
    ret.moTa_Text = ret.MoTa_Text;
  }
  // Normalize LoaiBenhPham_Id -> loaiBenhPham_Id
  if (ret.LoaiBenhPham_Id && !ret.loaiBenhPham_Id) {
    ret.loaiBenhPham_Id = ret.LoaiBenhPham_Id;
  }
  // Normalize ketluan -> ket_luan (chuẩn hóa từ WPF)
  if (ret.ketluan && !ret.ket_luan) {
    ret.ket_luan = ret.ketluan;
  }
  return convertDecimal128(ret);
};

XML3Schema.set('toJSON',{
  transform: normalizeTransform,
});

XML3Schema.set('toObject', {
  transform: normalizeTransform,
});

module.exports = mongoose.model('XML3', XML3Schema);
