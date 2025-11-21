#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
LOG_DIR="$ROOT_DIR/.logs"
PID_DIR="$ROOT_DIR/.pids"
FRONT_DIR="$ROOT_DIR/frontend"
HARDHAT_PORT=8545
HTTP_PORT=8080

mkdir -p "$LOG_DIR" "$PID_DIR"

function port_in_use() {
  local port=$1
  lsof -i :"$port" >/dev/null 2>&1
}

echo "[1/4] 启动本地 Hardhat 节点 (如未运行)"
if port_in_use "$HARDHAT_PORT"; then
  echo " - 端口 $HARDHAT_PORT 已占用，跳过启动。"
else
  (cd "$ROOT_DIR" && HARDHAT_DISABLE_TELEMETRY_PROMPT=true npx hardhat node > "$LOG_DIR/hardhat-node.log" 2>&1 & echo $! > "$PID_DIR/hardhat-node.pid")
  sleep 2
  echo " - Hardhat 节点已启动，日志: $LOG_DIR/hardhat-node.log"
fi

echo "[2/4] 部署合约到本地网络"
DEPLOY_LOG="$LOG_DIR/deploy.log"
(cd "$ROOT_DIR" && npm run deploy) 2>&1 | tee "$DEPLOY_LOG"
ADDR=$(sed -n 's/.*合约地址:\s*//p' "$DEPLOY_LOG" | tail -n1)
if [[ -z "$ADDR" ]]; then
  echo "部署未解析到合约地址，请检查日志: $DEPLOY_LOG" >&2
  exit 1
fi
echo " - 解析到合约地址: $ADDR"

echo "[3/4] 更新前端配置地址"
CFG_FILE="$FRONT_DIR/config.js"
if [[ -f "$CFG_FILE" ]]; then
  # macOS sed 需要 -i ''
  sed -i '' "s/CONTRACT_ADDRESS: '.*'/CONTRACT_ADDRESS: '$ADDR'/" "$CFG_FILE"
  echo " - 已写入 $CFG_FILE"
else
  echo " - 未找到 $CFG_FILE，跳过写入" >&2
fi

echo "[4/4] 启动前端静态服务器 (如未运行)"
if port_in_use "$HTTP_PORT"; then
  echo " - 端口 $HTTP_PORT 已占用，跳过启动。"
else
  (cd "$FRONT_DIR" && python3 -m http.server "$HTTP_PORT" > "$LOG_DIR/frontend.log" 2>&1 & echo $! > "$PID_DIR/frontend.pid")
  sleep 1
  echo " - 前端已启动，日志: $LOG_DIR/frontend.log"
fi

echo "完成。一键预览地址: http://localhost:$HTTP_PORT/"
if command -v open >/dev/null 2>&1; then
  open "http://localhost:$HTTP_PORT/" || true
fi