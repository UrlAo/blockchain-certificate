@echo off
setlocal EnableExtensions EnableDelayedExpansion

set ROOT=%~dp0..
set LOG_DIR=%ROOT%\.logs
set PID_DIR=%ROOT%\.pids
set FRONT_DIR=%ROOT%\frontend
set HARDHAT_PORT=8545
set HTTP_PORT=8080

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%PID_DIR%" mkdir "%PID_DIR%"

if not exist "%ROOT%\node_modules\.bin\hardhat.cmd" (
  echo [0/4] 安装项目依赖（首次运行）
  call npm install --no-audit --no-fund --no-progress --registry=https://registry.npmmirror.com > "%LOG_DIR%\install.log" 2>&1
  if errorlevel 1 (
    echo  - 依赖安装失败，请查看: %LOG_DIR%\install.log
    goto :end
  ) else (
    echo  - 依赖安装完成
  )
)

echo [1/4] 启动本地 Hardhat 节点
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:HARDHAT_DISABLE_TELEMETRY_PROMPT='true'; $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','"%ROOT%\\node_modules\\.bin\\hardhat.cmd" node ^> .logs\\hardhat-node.log 2^>^&1' -WorkingDirectory '%ROOT%' -WindowStyle Hidden -PassThru; Set-Content '.pids\\hardhat-node.pid' $proc.Id"
call :wait_port_open %HARDHAT_PORT% 15
if not %ERRORLEVEL%==0 (
  echo  - Hardhat 节点启动失败，请检查日志: %LOG_DIR%\hardhat-node.log
  goto :end
)
echo  - Hardhat 节点已启动，日志: %LOG_DIR%\hardhat-node.log

echo [2/4] 部署合约到本地网络
set HARDHAT_DISABLE_TELEMETRY_PROMPT=true
call "%ROOT%\node_modules\.bin\hardhat.cmd" run scripts\deploy.js --network localhost > "%LOG_DIR%\deploy.log" 2>&1
if not exist "%LOG_DIR%\contract.addr" (
  echo 部署未解析到合约地址，请检查日志: %LOG_DIR%\deploy.log
  goto :end
)

echo [3/4] 更新前端配置地址
powershell -NoProfile -ExecutionPolicy Bypass -Command "$addr = (Get-Content '%LOG_DIR%\\contract.addr').Trim(); $cfg = '%FRONT_DIR%\\config.js'; if (Test-Path $cfg) { (Get-Content $cfg) -replace \"CONTRACT_ADDRESS: '\\s*0x[0-9a-fA-F]{40}\\s*'\", \"CONTRACT_ADDRESS: '$addr'\" | Set-Content $cfg; Write-Host (' - 已写入 ' + $cfg) } else { Write-Host (' - 未找到 ' + $cfg) }"

echo [4/4] 启动前端静态服务器 (如未运行)
call :port_in_use %HTTP_PORT%
if %ERRORLEVEL%==0 (
  echo  - 端口 %HTTP_PORT% 已占用，跳过启动。
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','"%ROOT%\\node_modules\\.bin\\http-server.cmd" ./frontend -p %HTTP_PORT% --cors ^> .logs\\frontend.log 2^>^&1' -WorkingDirectory '%ROOT%' -WindowStyle Hidden -PassThru; Set-Content '.pids\\frontend.pid' $proc.Id; Start-Sleep -Seconds 1"
  echo  - 前端已启动，日志: %LOG_DIR%\frontend.log
)

echo 完成。一键预览地址: http://localhost:%HTTP_PORT%/
start "" http://localhost:%HTTP_PORT%/

goto :end

:port_in_use
set PORT=%1
powershell -NoProfile -Command "try { (New-Object System.Net.Sockets.TcpClient('127.0.0.1', %PORT%)).Close(); exit 0 } catch { exit 1 }"

:wait_port_open
set PORT=%1
set SECS=%2
for /L %%i in (1,1,%SECS%) do (
  powershell -NoProfile -Command "try { (New-Object System.Net.Sockets.TcpClient('127.0.0.1', %PORT%)).Close(); exit 0 } catch { exit 1 }"
  if %ERRORLEVEL%==0 (
    exit /b 0
  )
  ping -n 2 127.0.0.1 >nul
)
exit /b 1

:end
endlocal