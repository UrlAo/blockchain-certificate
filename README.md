# 区块链证书存证系统

基于区块链技术的证书发行与验证示例项目，使用 Hardhat 在本地链部署 Solidity 合约，并通过纯静态页面（`ethers.js`）进行交互。

## 技术栈
- Solidity（合约）：`contracts/Certificate.sol`
- Hardhat（本地链与部署）：`hardhat.config.js`、`scripts/deploy.js`
- 前端（静态页面 + ethers.js CDN）：`frontend/*.html`

## 目录结构
- `contracts/Certificate.sol` 合约：定义证书的发行与验证逻辑
- `scripts/deploy.js` 部署脚本：部署并打印合约地址
- `hardhat.config.js` Hardhat 配置：Solidity 版本与网络设置
- `frontend/index.html` 首页：导航至发行与验证
- `frontend/issuer.html` 发行页面：连接钱包、计算文件哈希并发行
- `frontend/verifier.html` 验证页面：计算文件哈希并查询合约
- `abi.json` 合约 ABI（可选）：由 `get-abi.js` 生成

## 前置条件
- Node.js（建议 18+）与 npm
- 浏览器钱包 MetaMask

## 快速开始
1. 安装依赖
   ```bash
   npm install
   ```
2. 启动本地链（保持运行）
   ```bash
   HARDHAT_DISABLE_TELEMETRY_PROMPT=true npx hardhat node
   ```
3. 另开终端部署合约到本地网络
   ```bash
   npm run deploy
   ```
   记录输出的合约地址，例如：`0x5FbDB2315678afecb367f032d93F642f64180aa3`
4. 启动前端（进入 `frontend` 目录）
   ```bash
   python3 -m http.server 8080
   # 或
   npx http-server .
   ```
5. 打开浏览器访问 `http://localhost:8080/`，在 MetaMask 选择 `Localhost 8545` 网络。

## 部署与前端配置
- 将部署得到的合约地址写入：
  - `frontend/config.js` 的 `CONTRACT_ADDRESS`
- 若修改了合约，请重新编译并更新前端 ABI：
  ```bash
  npx hardhat compile
  node get-abi.js
  ```
  然后将最新 ABI 写入 `frontend/abi.json`（前端会自动加载）。

拓展：项目已支持自动网络切换（31337）与动态配置加载（地址与 ABI 从 `frontend/config.js` 与 `frontend/abi.json` 加载）。

## 使用说明
### 一、准备钱包与网络
- 在 MetaMask 添加或切换到本地网络：
  - RPC URL：`http://127.0.0.1:8545`
  - Chain ID：`31337`（十六进制 `0x7A69`）
  - Currency Symbol：`ETH`
- 导入有余额的本地账户（Hardhat 节点终端打印的私钥），推荐导入部署者账户：
  - 部署者地址：见 `npm run deploy` 的日志输出
  - 私钥示例：`0xac0974bec39a17e36...`（仅用于本地开发，勿用于主网）
- 前端已内置网络检查与自动切换；若钱包弹出添加/切换网络确认框，请同意。

### 二、发行证书（管理员）
- 打开 `http://localhost:8080/issuer.html`，点击“连接钱包”，确认页面显示地址与 `chainId: 31337`。
- 选择证书文件并点击“计算文件哈希”，按钮将自动启用。
- 填写学号、姓名、学位，点击“发行证书到区块链”，在钱包中确认交易。

### 三、验证证书（只读）
- 打开 `http://localhost:8080/verifier.html`，上传需要验证的文件。
- 系统计算哈希并调用合约 `verifyCertificate`，若有效将展示学号、姓名、学位与发行时间。

## 常见问题与排查
- 前端调用失败或返回无效
  - 检查合约地址是否与部署输出一致（两处都需更新）。
- `Only admin can call this function`
  - 使用部署者账户（管理员）进行发行，或重新部署使当前连接地址为管理员。
- 本地链未启动或 8545 端口被占用
  - 确保 `npx hardhat node` 正在运行；必要时修改 `hardhat.config.js` 端口。
- ABI 不一致导致方法签名错误
  - 重新编译并更新前端使用的 ABI。
- 使用 `file://` 打开 HTML 导致钱包交互异常
  - 通过本地 HTTP 服务访问页面（例如 `http://localhost:8080/`）。

## 开发提示（代码入口）
- 管理员逻辑与限制：`contracts/Certificate.sol` 的 `constructor()` 和 `modifier onlyAdmin`
- 发行/验证方法：`issueCertificate(...)`、`verifyCertificate(...)`
- 部署脚本：`scripts/deploy.js`
- 网络与编译配置：`hardhat.config.js`

## 许可证
- 采用 ISC 许可证（见 `package.json`）。