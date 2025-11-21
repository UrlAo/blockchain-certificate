## 目标
- 修复发行页“network does not support ENS”错误，并确保带 CID 的发行接口可用。

## 方案
- 将前端签名发行从 `provider.send('eth_signTypedData_v4', ...)` 改为 `signer._signTypedData(domain, types, value)`，避免 ENS 解析与 unknown network 的问题。
- 保留已加载的动态 ABI（`frontend/abi.json`）与最新合约地址（`frontend/config.js`），确保 `issueCertificateWithCid` 与 `issueWithSig` 方法存在。

## 修改点
- 更新 `frontend/issuer.html` 的 `issueWithSignature` 函数：
  - 构造 `domain/types/value`，使用 `signer._signTypedData` 生成签名
  - 调用 `contract.issueWithSig(value.certHash, studentId, studentName, degree, cid, Number(nonce), sig)`

## 验证
- 刷新发行页，依次执行：连接钱包 → 计算文件哈希 → 填写信息（可选 CID）→ 使用“签名发行”与“直接发行”两种路径，确认均成功。