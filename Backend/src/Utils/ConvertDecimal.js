// utils/decimal128-to-json.js
const { Decimal128 } = require('bson');

function convertDecimal128(obj) {
  if (!obj || typeof obj !== 'object') return obj;

  for (const key of Object.keys(obj)) {
    const val = obj[key];

    if (val instanceof Decimal128) {
      // chọn 1 trong 2 dòng dưới:
      obj[key] = Number(val.toString());         // ✅ an toàn (string)
      // obj[key] = Number(val.toString()); // ⚠️ có thể mất chính xác
    } else if (Array.isArray(val)) {
      obj[key] = val.map(convertDecimal128);
    } else if (val && typeof val === 'object') {
      obj[key] = convertDecimal128(val);
    }
  }
  return obj;
}

module.exports = { convertDecimal128 };
