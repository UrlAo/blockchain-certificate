const fs = require('fs');
const abi = require('./artifacts/contracts/Certificate.sol/CertificateRegistry.json').abi;
fs.writeFileSync('abi.json', JSON.stringify(abi, null, 2));
console.log('ABI 已保存到 abi.json');