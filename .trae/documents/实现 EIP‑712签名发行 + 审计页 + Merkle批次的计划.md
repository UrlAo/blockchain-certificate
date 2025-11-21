## 目标
- 扩展现有系统，优先交付：EIP‑712 线下签名发行、审计页（事件列表与导出）、基础 Merkle 批次登记与验证。
- 保持向后兼容，前端继续使用动态地址与 ABI 加载。

## 合约改动
- EIP‑712 签名发行
  - 新增域 `EIP712Domain(name:"CertificateRegistry", version:"1", chainId, verifyingContract)`。
  - 类型 `Certificate(bytes32 certHash, string studentId, string studentName, string degree, string ipfsCid, uint256 nonce)`。
  - 存储 `mapping(address=>uint256) nonces`；函数 `issueWithSig(payload, signature)`：
    - `recover` 出签名者并校验其为发行人；校验 `nonce` 递增；写入证书；事件沿用 `CertificateIssued`。
- 审计支持
  - 事件已齐全（发行/撤销/发行人增删），无需新增；保留现有查询接口。
- Merkle 批次（基础版）
  - 新增 `mapping(bytes32=>bool) batchRoots` + 事件 `BatchRootIssued(bytes32 root, string batchId)`，函数 `issueBatchRoot(bytes32 root, string batchId)`。
  - 验证函数 `verifyLeaf(bytes32 root, bytes32 leaf, bytes32[] proof)`（返回布尔值）；不写入明细，仅用于大规模哈希登记场景。

## 前端改动
- 发行页
  - 新增“签名发行”区：生成 TypedData → 钱包签名 → 调用 `issueWithSig`；显示签名与交易哈希，可复制。
  - 保留现有“直接发行/带 CID 发行”与撤销功能。
- 审计页（新增 `frontend/audit.html`）
  - 加载 `ethers` 与 `config.js/abi.json`，分页读取并展示事件：`CertificateIssued/CertificateRevoked/IssuerAdded/IssuerRemoved`。
  - 支持筛选（类型/时间范围）与导出 CSV/JSON；显示合约地址与网络。
- Merkle 批次页（新增 `frontend/batch.html`）
  - 批量选择文件 → 计算每个哈希 → 构建 Merkle 树（前端 JS，使用 keccak256）→ 展示根与大小 → 调用 `issueBatchRoot`。
  - 提供单个文件的证明生成与 `verifyLeaf(root, leaf, proof)` 验证演示。

## 脚本与测试
- 脚本
  - 新增 `scripts/deploy-sepolia.js`（占位），后续用于测试网部署。
  - 新增 `scripts/tools/merkle.js`（前端/Node 复用的 Merkle 构建与验证工具）。
- 单元测试（Hardhat）
  - 覆盖：`issueWithSig` 正常流程与错误用例（非发行人签名/重放）；
  - 撤销流程与权限边界；
  - Merkle：`issueBatchRoot` 与 `verifyLeaf` 正确性。

## README 更新
- 增加“签名发行”与“审计页/批量登记”的使用说明与命令；保留一键启动。

## 验证与交付
- 本地链端到端验证：直接发行/签名发行/撤销/审计页事件/批量登记与叶子验证。
- 不引入第三方 UI 框架；仅使用现有 `ethers` 与原生 JS/CSS。

## 执行顺序
1) 合约实现与 ABI 更新（签名发行、批次根与验证）；
2) 前端添加审计页与批量页，发行页加入签名发行；
3) 单元测试与 README 更新；
4) 本地验证并提交变更。