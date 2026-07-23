import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, writeFileSync, readFileSync, unlinkSync } from 'node:fs';
import { get } from 'node:https';
import { DatabaseSync } from 'node:sqlite';

console.log('NODE_VERSION', process.version);
console.log('ARCH', process.arch, 'PLATFORM', process.platform);
assert.equal(process.arch, 'arm64');
assert.equal(process.platform, 'ios');

assert.equal(createHash('sha256').update('node-ios').digest('hex').length, 64);
console.log('CRYPTO_OK');

const testPath = `/tmp/node24-ios-${process.pid}.txt`;
writeFileSync(testPath, 'ok');
assert.equal(readFileSync(testPath, 'utf8'), 'ok');
unlinkSync(testPath);
console.log('FS_OK');

const db = new DatabaseSync(':memory:');
assert.equal(db.prepare('select 40 + 2 as answer').get().answer, 42);
db.close();
console.log('SQLITE_OK');

const echoPath = existsSync('/var/jb/usr/bin/echo') ? '/var/jb/usr/bin/echo' : '/bin/echo';
assert.equal(execFileSync(echoPath, ['child-ok'], { encoding: 'utf8' }).trim(), 'child-ok');
console.log('CHILD_PROCESS_OK');

const statusCode = await new Promise((resolve, reject) => {
  const request = get('https://registry.npmjs.org/npm', (response) => {
    response.resume();
    resolve(response.statusCode);
  });
  request.setTimeout(15000, () => request.destroy(new Error('TLS request timed out')));
  request.on('error', reject);
});
assert.equal(statusCode, 200);
console.log('TLS_HTTPS_OK', statusCode);

console.log('SMOKE_DONE');
