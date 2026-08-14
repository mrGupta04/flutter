const assert = require('assert');
const {
  MAX_LABS_PER_REQUEST,
  assertAllowedFileType,
} = require('../src/db/prescriptionRequestRepositories');

assert.strictEqual(MAX_LABS_PER_REQUEST, 4);
assert.strictEqual(assertAllowedFileType('PDF'), 'pdf');
assert.strictEqual(assertAllowedFileType('image/jpeg'), 'jpg');
try {
  assertAllowedFileType('docx');
  assert.fail('should reject docx');
} catch (e) {
  assert.strictEqual(e.statusCode, 400);
}

console.log('prescription request unit checks passed');