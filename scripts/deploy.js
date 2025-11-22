const { ethers } = require("hardhat");

async function main() {
  console.log("开始部署证书合约...");
  
  // 获取部署者账户
  const [deployer] = await ethers.getSigners();
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