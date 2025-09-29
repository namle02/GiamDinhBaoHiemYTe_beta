const mongoose = require('mongoose');

const XML10Schema = new mongoose.Schema({
  id:            { type: Number, required: false },
  Ma_Lk:         { type: String, default: null },
  So_Seri:       { type: String, default: null },
  So_Ct:         { type: String, default: null },
  So_Ngay:       { type: Number, default: null },
  Don_Vi:        { type: String, default: null },
  Chan_DoAn_Rv:  { type: String, default: null },
  Tu_Ngay:       { type: String, default: null },
  Den_Ngay:      { type: String, default: null },
  Ma_Ttdv:       { type: String, default: null },
  Ten_Bs:        { type: String, default: null },
  Ma_Bs:         { type: String, default: null },
  Ngay_Ct:       { type: String, default: null },
  Du_Phong:      { type: String, default: null }
}, {
  timestamps: true,
  strict: false
});

module.exports = mongoose.model('XML10', XML10Schema);
