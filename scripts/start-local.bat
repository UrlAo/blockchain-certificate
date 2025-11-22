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

echo [1/4] 启动本地 Hardhat 节点 (如未运行)
call :port_in_use %HARDHAT_PORT%
if %ERRORLEVEL%==0 (
  echo  - 端口 %HARDHAT_PORT% 已占用，跳过启动。
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:HARDHAT_DISABLE_TELEMETRY_PROMPT='true'; $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','npx hardhat node ^> .logs\\hardhat-node.log 2^>^&1' -WorkingDirectory '%ROOT%' -WindowStyle Hidden -PassThru; Set-Content '.pids\\hardhat-node.pid' $proc.Id; Start-Sleep -Seconds 2"
  echo  - Hardhat 节点已启动，日志: %LOG_DIR%\hardhat-node.log
)

echo [2/4] 部署合约到本地网络
call npm run deploy > "%LOG_DIR%\deploy.log" 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$log=Get-Content '%LOG_DIR%\\deploy.log'; $m = $log | Select-String -Pattern '合约地址:\s*(0x[0-9a-fA-F]{40})' | Select-Object -Last 1; if (-not $m) { Write-Error '部署未解析到合约地址'; exit 1 }; $addr=$m.Matches[0].Groups[1].Value; Write-Host (' - 解析到合约地址: ' + $addr); Set-Content '%LOG_DIR%\\contract.addr' $addr;"
if errorlevel 1 (
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
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','npx http-server ./frontend -p %HTTP_PORT% --cors ^> .logs\\frontend.log 2^>^&1' -WorkingDirectory '%ROOT%' -WindowStyle Hidden -PassThru; Set-Content '.pids\\frontend.pid' $proc.Id; Start-Sleep -Seconds 1"
  echo  - 前端已启动，日志: %LOG_DIR%\frontend.log
)

echo 完成。一键预览地址: http://localhost:%HTTP_PORT%/
start "" http://localhost:%HTTP_PORT%/

goto :end

:port_in_use
set PORT=%1
netstat -ano | findstr ":%PORT% " >nul
if %ERRORLEVEL%==0 (
  exit /b 0
) else (
  exit /b 1
)

:end
endlocal