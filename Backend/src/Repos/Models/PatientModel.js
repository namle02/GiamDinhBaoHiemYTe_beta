const mongoose = require('mongoose');

// Import các schema con đã tạo ở trên
const XML0Model = require('./XML_Model/XML0');
const XML1Model = require('./XML_Model/XML1');
const XML2Model = require('./XML_Model/XML2');
const XML3Model = require('./XML_Model/XML3');
const XML4Model = require('./XML_Model/XML4');
const XML5Model = require('./XML_Model/XML5');
const XML6Model = require('./XML_Model/XML6');
const XML7Model = require('./XML_Model/XML7');
const XML8Model = require('./XML_Model/XML8');
const XML9Model = require('./XML_Model/XML9');
const XML10Model = require('./XML_Model/XML10');
const XML11Model = require('./XML_Model/XML11');
const XML13Model = require('./XML_Model/XML13');
const XML14Model = require('./XML_Model/XML14');
const XML15Model = require('./XML_Model/XML15');
const DsBenhNhanLoiMaMayModel = require('./XML_Model/DsBenhNhanLoiMaMay');

const XML0Schema = XML0Model.schema;
const XML1Schema = XML1Model.schema;
const XML2Schema = XML2Model.schema;
const XML3Schema = XML3Model.schema;
const XML4Schema = XML4Model.schema;
const XML5Schema = XML5Model.schema;
const XML6Schema = XML6Model.schema;
const XML7Schema = XML7Model.schema;
const XML8Schema = XML8Model.schema;
const XML9Schema = XML9Model.schema;
const XML10Schema = XML10Model.schema;
const XML11Schema = XML11Model.schema;
const XML13Schema = XML13Model.schema;
const XML14Schema = XML14Model.schema;
const XML15Schema = XML15Model.schema;
const DsBenhNhanLoiMaMaySchema = DsBenhNhanLoiMaMayModel.schema;

const PatientDataSchema = new mongoose.Schema({
    PatientID: { type: String, default: null },
    Xml0:      [XML0Schema],
    Xml1:      [XML1Schema],
    Xml2:      [XML2Schema],
    Xml3:      [XML3Schema],
    Xml4:      [XML4Schema],
    Xml5:      [XML5Schema],
    Xml6:      [XML6Schema],
    Xml7:      [XML7Schema],
    Xml8:      [XML8Schema],
    Xml9:      [XML9Schema],
    Xml10:     [XML10Schema],
    Xml11:     [XML11Schema],
    Xml13:     [XML13Schema],
    Xml14:     [XML14Schema],
    Xml15:     [XML15Schema],
    DsBenhNhanLoiMaMay: [DsBenhNhanLoiMaMaySchema]
  }, {
    timestamps: true
  });
  
  module.exports = mongoose.model('PatientData', PatientDataSchema);
  