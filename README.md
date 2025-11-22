# 区块链证书存证系统

基于区块链技术的证书发行与验证示例项目，使用 Hardhat 在本地链部署 Solidity 合约，并通过纯静态页面（`ethers.js`）进行交互。

## 技术栈
- Solidity（合约）：`contracts/Certificate.sol`
- Hardhat（本地链与部署）：`hardhat.config.js`、`scripts/deploy.js`
- 前端（静态页面 + ethers.js CDN）：`frontend/index.html`、`frontend/issuer.html`、`frontend/verifier.html`、`frontend/audit.html`、`frontend/batch.html`

## 目录结构
- `contracts/Certificate.sol` 合约：定义证书的发行与验证逻辑
- `scripts/deploy.js` 部署脚本：部署并打印合约地址
- `hardhat.config.js` Hardhat 配置：Solidity 版本与网络设置
- `frontend/index.html` 首页：导航至发行与验证
- `frontend/issuer.html` 发行页面：连接钱包、计算文件哈希并发行，支持签名发行与撤销后重发
- `frontend/verifier.html` 验证页面：计算文件哈希并查询合约
- `frontend/audit.html` 审计页面：查看合约事件记录（发行、撤销、发行人变更、批次登记）
- `frontend/batch.html` 批次页面：计算 Merkle Root 并登记、对单文件进行证明校验
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
4. 启动前端（在项目根目录）
  ```bash
  python3 -m http.server 8080
  # 或（推荐）
  npx http-server ./frontend -p 8080 --cors
  ```
5. 打开浏览器访问 `http://localhost:8080/`，在 MetaMask 选择 `Localhost 8545` 网络。

### 一键启动（推荐）
- macOS/Linux:
```bash
npm run start-local
```
- Windows:
```bash
npm run start-win
```
- 自动启动本地链（若未运行）、部署合约并解析地址、写入 `frontend/config.js`、启动前端并打开浏览器。
- 日志输出位置：`.logs/`；进程 PID：`.pids/`。
- Windows 批处理脚本：`scripts/start-local.bat`

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
- 选择证书文件（支持拖拽到上传区域）并点击“计算文件哈希”，可一键复制哈希。
- 填写学号、姓名、学位后点击“发行证书到区块链”，在钱包中确认交易；页面会显示交易哈希与进度。
- 可选填写 `IPFS CID`，将与证书记录一并保存；管理员可在发行页撤销当前证书（需先计算哈希并填写原因）。
- 若证书已发行且未撤销，系统会阻止重复发行；若证书已撤销，允许使用同一哈希重新发行，并在页面提示“将执行重新发行”。

### 三、签名发行（EIP‑712）
- 在发行页填写信息并点击“签名发行”，钱包会对结构化数据进行签名，随后由合约 `issueWithSig(...)` 完成发行。
- 支持携带 `IPFS CID`；若检测到证书“已发行未撤销”则阻止签名重复发行，若“已撤销”则允许签名重发并提示。

### 四、验证证书（只读）
- 打开 `http://localhost:8080/verifier.html`，上传需要验证的文件。
- 系统计算哈希并调用合约 `getCertificate`，若有效显示证书信息与 CID；若已撤销则展示原因与时间；支持复制文件哈希。

### 五、审计事件
- 打开 `http://localhost:8080/audit.html`，查看 `CertificateIssued`、`CertificateRevoked`、`IssuerAdded`、`IssuerRemoved`、`BatchRootIssued` 等事件的历史记录，并支持导出。

### 六、批次登记与证明
- 打开 `http://localhost:8080/batch.html`，选择多个文件，页面会计算每个文件的 SHA‑256，再哈希为叶子并滚动计算 Merkle Root。
- 使用“登记批次”将 Root 与批次 ID 写入链上；在“单文件证明”区域可构造证明并调用 `verifyLeaf(root, leaf, proof)` 校验。

## 常见问题与排查
- 前端调用失败或返回无效
  - 检查合约地址是否与部署输出一致（两处都需更新）。
- `Only admin can call this function`
  - 使用部署者账户（管理员）进行发行，或重新部署使当前连接地址为管理员。
- 本地链未启动或 8545 端口被占用
  - 确保 `npx hardhat node` 正在运行；必要时修改 `hardhat.config.js` 端口。
- ABI 不一致导致方法签名错误
  - 修改合约后需重新编译，并将最新 ABI 写入 `frontend/abi.json`。

- 撤销后无法重发
  - 当前版本支持“撤销后重发”。若仍无法重发，请确认已更新前端与合约并重新部署；未撤销的证书仍不可重复发行。

## 重要变更
- 撤销后重发：对已撤销的同一证书哈希允许重新发行，未撤销的证书仍禁止重复发行。
- 签名发行：支持 EIP‑712 的结构化数据签名后发行，保留发行人权限校验与 nonce 递增。
- 批次登记与校验：支持 Merkle Root 登记与单文件证明校验。
- 审计页：新增事件审计页面，便于查看链上历史记录。

## 开发提示（代码入口）
- 管理员逻辑与限制：`contracts/Certificate.sol` 的 `constructor()` 和 `modifier onlyAdmin`
- 发行/验证方法：`issueCertificate(...)`、`verifyCertificate(...)`
- 允许撤销后重发的校验：`contracts/Certificate.sol:75`、`contracts/Certificate.sol:99`、`contracts/Certificate.sol:128`、`contracts/Certificate.sol:262`
- 部署脚本：`scripts/deploy.js`
- 网络与编译配置：`hardhat.config.js`

## 许可证
- 采用 ISC 许可证（见 `package.json`）。