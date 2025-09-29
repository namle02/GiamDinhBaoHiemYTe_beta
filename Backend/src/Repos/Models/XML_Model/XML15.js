const mongoose = require('mongoose');

const XML15Schema = new mongoose.Schema({
  id:                    { type: Number, required: false },
  Ma_Lk:                 { type: String, default: null },
  Stt:                   { type: Number, default: null },
  Ma_Bn:                 { type: String, default: null },
  Ho_Ten:                { type: String, default: null },
  So_Cccd:               { type: String, default: null },
  PhanLoai_Lao_ViTri:    { type: Number, default: null },
  PhanLoai_Lao_Ts:       { type: Number, default: null },
  PhanLoai_Lao_Hiv:      { type: Number, default: null },
  PhanLoai_Lao_Vk:       { type: Number, default: null },
  PhanLoai_Lao_Kt:       { type: Number, default: null },
  Loai_Dtri_Lao:         { type: Number, default: null },
  Ngaybd_Dtri_Lao:       { type: String, default: null },
  Phacdo_Dtri_Lao:       { type: Number, default: null },
  Ngaykt_Dtri_Lao:       { type: String, default: null },
  Ket_Qua_Dtri_Lao:      { type: Number, default: null },
  Ma_Cskcb:              { type: String, default: null },
  Ngaykd_Hiv:            { type: String, default: null },
  Bddt_Arv:              { type: String, default: null },
  Ngay_Bat_Dau_Dt_Ctx:   { type: String, default: null },
  Du_Phong:              { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML15', XML15Schema);
