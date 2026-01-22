const mongoose = require('mongoose');

const XML5Schema = new mongoose.Schema({
  id:               { type: Number, required: false },
  Ma_Lk:            { type: String, default: null },
  Stt:              { type: Number, default: null },
  Dien_Bien_Ls:     { type: String, default: null },
  Giai_DoAn_Benh:   { type: String, default: null },
  Hoi_Chan:         { type: String, default: null },
  Phau_Thuat:       { type: String, default: null },
  Thoi_Diem_Dbls:   { type: String, default: null },
  Nguoi_Thuc_Hien:  { type: String, default: null },
  Du_Phong:         { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML5', XML5Schema);
