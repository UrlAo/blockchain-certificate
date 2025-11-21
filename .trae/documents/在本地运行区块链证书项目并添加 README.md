## 项目概览
- 技术栈: Solidity 合约 + Hardhat 本地链 + 纯静态前端（`ethers.js` CDN）。
- 合约核心:
  - 构造函数设置管理员 `constructor()` 于 `contracts/Certificate.sol:22-25`。
  - 管理员限制 `modifier onlyAdmin` 于 `contracts/Certificate.sol:28-31`。
  - 发行证书 `issueCertificate(...)` 于 `contracts/Certificate.sol:40-57`。
  - 验证证书 `verifyCertificate(...)` 于 `contracts/Certificate.sol:64-81`。
- 部署脚本: 读取 signer 并部署合约，打印地址 `scripts/deploy.js:7-19`。
- 网络配置: Hardhat 本地网络 `hardhat.config.js:5-11`。
- 前端:
  - 发行页硬编码合约地址 `frontend/issuer.html:57`，初始化与交易 `frontend/issuer.html:247-253,295-305`。
  - 验证页硬编码合约地址并调用只读验证 `frontend/verifier.html:33,222-227,258-261`。

## 在 macOS 本地运行
- 前置条件
  - 安装 Node.js（建议 18+）与 npm，浏览器安装 MetaMask。
- 安装依赖
  - 在项目根执行: `npm install`
- 启动本地链
  - 终端 A: `npx hardhat node`
- 部署合约到本地链
  - 终端 B: `npm run deploy`
  - 记录输出的合约地址（如非 `0x5FbDB...`），更新到 `frontend/issuer.html:57` 与 `frontend/verifier.html:33`。
- 启动前端（静态服务器）
  - 进入 `frontend` 目录，任选其一: `python3 -m http.server 8080` 或 `npx http-server .`
  - 打开 `http://localhost:8080/index.html`，在 MetaMask 选择 `Localhost 8545` 网络。
- 体验流程
  - 在发行页选择证书文件，填写信息，点击发行并在钱包确认；在验证页上传同一文件查看验证结果。

## README 添加计划
- 将新增 `README.md`（中文），内容包含：
  - 项目简介与目标
  - 技术栈与架构概览
  - 前置条件（Node、MetaMask）
  - 快速开始（`npm install`、`npx hardhat node`、`npm run deploy`、前端启动命令）
  - 部署与前端配置（如何将部署地址写入 `frontend/issuer.html:57`、`frontend/verifier.html:33`）
  - 使用说明（发行与验证步骤与页面说明）
  - 常见问题（本地链未启动、合约地址不匹配、管理员权限、ABI 不一致、端口占用）
  - 项目结构（目录与关键文件清单）
  - 许可协议（沿用 `package.json` 的 `ISC`）

## 验证与注意事项
- 合约地址不匹配时前端会报错；需按部署输出更新两处地址。
- 发行需管理员账户（部署者），否则会触发 `Only admin can call this function`。
- 切勿用 `file://` 直接打开 HTML，使用 `http://localhost:...` 提供服务。
- 若修改合约，需重新编译并更新前端 ABI（可使用 `get-abi.js`）。

## 下一步执行
- 获得确认后我将：
  - 在你的环境中依次执行安装、启动本地链、部署合约、更新前端地址、启动静态服务器并验证端到端流程。
  - 创建并写入 `README.md`，包含上述章节与具体命令、代码引用与注意事项。

请确认是否按上述计划执行；README 语言默认中文。