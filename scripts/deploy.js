const { ethers } = require("hardhat");

async function main() {
  console.log("开始部署证书合约...");
  const signers = await ethers.getSigners();
  const deployer = signers[0];
  console.log("部署者地址:", deployer.address);
  
  // 部署合约
  const CertificateRegistry = await ethers.getContractFactory("CertificateRegistry");
  const certificateRegistry = await CertificateRegistry.deploy();
  
  await certificateRegistry.waitForDeployment();
  const contractAddress = await certificateRegistry.getAddress();
  
  console.log("证书合约部署成功!");
  console.log("合约地址:", contractAddress);
  console.log("管理员地址:", deployer.address);
  try {
    const fs = require('fs');
    const path = require('path');
    const logPath = path.resolve(__dirname, '..', '.logs', 'hardhat-node.log');
    let content = '';
    if (fs.existsSync(logPath)) {
      content = fs.readFileSync(logPath, 'utf8');
    }
    const accOut = path.resolve(__dirname, '..', '.logs', 'accounts.log');
    fs.mkdirSync(path.dirname(accOut), { recursive: true });
    const clean = content.replace(/\u001b\[[0-9;]*m/g, '');
    const lines = clean.split(/\r?\n/);
    const result = [];
    for (let i = 0; i < lines.length; i++) {
      const l = lines[i];
      const mAcc = l.match(/^Account #(\d+):\s+(0x[0-9a-fA-F]{40})/);
      if (mAcc) {
        let pk = '';
        for (let j = i + 1; j < Math.min(i + 4, lines.length); j++) {
          const l2 = lines[j];
          const mPk = l2.match(/^Private Key:\s+(0x[0-9a-fA-F]+)/);
          if (mPk) { pk = mPk[1]; break; }
        }
        result.push(`Account #${mAcc[1]}: ${mAcc[2]}`);
        result.push(`Private Key: ${pk || 'N/A'}`);
        result.push('');
      }
    }
    if (result.length > 0) {
      fs.writeFileSync(accOut, result.join('\n'), 'utf8');
      console.log("账户与私钥已写入:", accOut);
    } else {
      const basic = [];
      for (let i = 0; i < signers.length; i++) {
        const s = signers[i];
        basic.push(`Account #${i}: ${s.address}`);
      }
      fs.writeFileSync(accOut, basic.join('\n'), 'utf8');
      console.log("已写入账户地址:", accOut);
    }
  } catch (_) {}

  try {
    const fs = require('fs');
    const path = require('path');
    const out = path.resolve(__dirname, '..', '.logs', 'contract.addr');
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, contractAddress, 'utf8');
  } catch (e) {}
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });