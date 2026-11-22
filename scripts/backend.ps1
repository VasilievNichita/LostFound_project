param([ValidateSet('Start','Stop','Restart','Rotate')][string]$Action = 'Start')
$ErrorActionPreference = 'Stop'
$data = 'D:\PAM\data\L5'
$python = 'D:\PAM\tools\backend-python\Scripts\python.exe'
$source = 'D:\PAM\LostFound_project\server'
New-Item -ItemType Directory -Force $data | Out-Null
$recordPath = Join-Path $data 'process.json'
function Stop-Backend {
    if (!(Test-Path $recordPath)) { return }
    $record = Get-Content $recordPath -Raw | ConvertFrom-Json
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($record.pid)"
    if ($process -and $process.ExecutablePath -eq $python -and $process.CommandLine -like '*-m app.main*' -and $process.CreationDate.ToUniversalTime().Ticks -eq $record.createdTicks) {
        & taskkill /PID $record.pid /T /F | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Не удалось остановить сервер.' }
    } elseif ($process) { throw 'PID принадлежит другому процессу; остановка не выполнена.' }
    Remove-Item -LiteralPath $recordPath
}
if ($Action -in @('Stop','Restart','Rotate')) { Stop-Backend }
if ($Action -eq 'Stop') { Write-Host 'Сервер остановлен. База сохранена.'; return }
$secretPath = Join-Path $data 'jwt-secret.txt'
if ($Action -eq 'Rotate' -or !(Test-Path $secretPath)) { [Guid]::NewGuid().ToString('N') + [Guid]::NewGuid().ToString('N') | Set-Content $secretPath }
if (Test-Path $recordPath) {
    try { if ((Invoke-RestMethod http://127.0.0.1:8080/health -TimeoutSec 2).status -eq 'ok') { Write-Host 'Сервер уже работает.'; return } } catch { }
    Stop-Backend
}
if (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue) { throw 'Порт 8080 занят другим процессом. Его остановка не выполнялась.' }
$env:PAM_DATA_DIR = $data
$env:JWT_SECRET = (Get-Content $secretPath -Raw).Trim()
$env:PORT = '8080'
$env:TEMP = 'D:\PAM\tmp'; $env:TMP = $env:TEMP
$process = Start-Process $python -ArgumentList '-m app.main' -WorkingDirectory $source -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $data 'server.log') -RedirectStandardError (Join-Path $data 'errors.log')
$details = Get-CimInstance Win32_Process -Filter "ProcessId=$($process.Id)"
@{ pid=$process.Id; createdTicks=$details.CreationDate.ToUniversalTime().Ticks } | ConvertTo-Json | Set-Content $recordPath
Remove-Item Env:\JWT_SECRET
for ($n=0; $n -lt 40; $n++) {
    try { if ((Invoke-RestMethod http://127.0.0.1:8080/health -TimeoutSec 1).status -eq 'ok') { Write-Host 'LostFound API: http://127.0.0.1:8080'; return } } catch { }
    Start-Sleep -Milliseconds 250
}
throw "Сервер не запустился. Проверьте $data\errors.log"
