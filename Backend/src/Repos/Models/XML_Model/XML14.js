const mongoose = require('mongoose');

const XML14Schema = new mongoose.Schema({
  id:                { type: Number, required: false },
  Ma_Lk:             { type: String, default: null },
  So_GiayHen_Kl:     { type: String, default: null },
  Ma_Cskcb:          { type: String, default: null },
  Ho_Ten:            { type: String, default: null },
  Ngay_Sinh:         { type: String, default: null },
  Gioi_Tinh:         { type: Number, default: null },
  Dia_Chi:           { type: String, default: null },
  Ma_The_Bhyt:       { type: String, default: null },
  Gt_The_Den:        { type: String, default: null },
  Ngay_Vao:          { type: String, default: null },
  Ngay_Vao_Noi_Tru:  { type: String, default: null },
  Ngay_Ra:           { type: String, default: null },
  Ngay_Hen_Kl:       { type: String, default: null },
  Chan_DoAn_Rv:      { type: String, default: null },
  Ma_Benh_Chinh:     { type: String, default: null },
  Ma_Benh_Kt:        { type: String, default: null },
  Ma_Benh_Yhct:      { type: String, default: null },
  Ma_DoiTuong_Kcb:   { type: String, default: null },
  Ma_Bac_Si:         { type: String, default: null },
  Ma_Ttdv:           { type: String, default: null },
  Ngay_Ct:           { type: String, default: null },
  Du_Phong:          { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML14', XML14Schema);
