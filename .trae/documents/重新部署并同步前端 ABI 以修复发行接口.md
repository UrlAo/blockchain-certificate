## 目标
- 修复前端报错“issueCertificateWithCid is not a function”，确保新合约与前端 ABI、地址一致，并可正常发行/撤销/签名发行。

## 执行步骤
- 重新编译与部署到本地链：`npx hardhat compile` → `npm run deploy`（也可直接用 `npm run start-local` 一键执行）
- 同步前端 ABI：运行 `node get-abi.js` 生成最新 `abi.json`，复制到 `frontend/abi.json`
- 确认前端地址：`frontend/config.js` 的 `CONTRACT_ADDRESS` 指向最新部署地址（一键脚本会写入）
- 启动前端服务器并验证发行页：
  - 连接钱包 → 计算文件哈希 → 填写信息与可选 CID → 正常调用 `issueCertificateWithCid` 或 `issueCertificate`
  - 验证签名发行与撤销功能

## 交付与验证
- 打开 `http://localhost:8080/issuer.html` 与 `verifier.html`，完成端到端测试；如仍提示函数不存在，执行硬刷新以清除旧缓存。