require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      viaIR: true
    }
  },
  networks: {
    // 配置为使用本地Hardhat网络进行测试
    localhost: {
      url: "http://127.0.0.1:8545"
    }
  }
};