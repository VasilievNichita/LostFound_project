param([ValidateSet('L4','L5')][string]$Stage = 'L5')
$ErrorActionPreference = 'Stop'
. D:\PAM\scripts\env.ps1
$project = if ($Stage -eq 'L4') { 'D:\PAM\demo\L4' } else { 'D:\PAM\LostFound_project' }
if ($Stage -eq 'L5') { & D:\PAM\scripts\backend.ps1 -Action Start }
# A visible emulator is needed for a live presentation.
$emulator = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*PAM_API_37*' -and $_.Name -like 'qemu*' }
if ($emulator -and $emulator.CommandLine -like '*-no-window*') {
    & adb -s emulator-5554 emu kill | Out-Null
    Start-Sleep -Seconds 3
}
$device = & adb devices
if (!($device -match 'emulator-5554\s+device')) {
    Start-Process D:\PAM\tools\android-sdk\emulator\emulator.exe -ArgumentList '-avd PAM_API_37 -gpu auto -memory 2048 -no-snapshot'
}
for ($n=0; $n -lt 120; $n++) {
    $boot = & adb -s emulator-5554 shell getprop sys.boot_completed 2>$null
    if ($boot -match '1') { break }
    Start-Sleep -Seconds 1
}
if ($boot -notmatch '1') { throw 'Эмулятор ещё не загрузился. Повторите запуск через минуту.' }
if ($Stage -eq 'L5') {
    $apk = 'D:\PAM\output\LostFound_L5_debug.apk'
    if (!(Test-Path -LiteralPath $apk)) { throw 'Не найден проверенный APK в D:\PAM\output.' }
    & adb -s emulator-5554 install -r $apk
    if ($LASTEXITCODE -ne 0) { throw 'Не удалось установить приложение.' }
    & adb -s emulator-5554 shell am force-stop md.campus.lost_found
    & adb -s emulator-5554 shell am start -n md.campus.lost_found/.MainActivity
    if ($LASTEXITCODE -ne 0) { throw 'Не удалось открыть приложение.' }
    return
}
Set-Location $project
& flutter pub get --offline
if ($LASTEXITCODE -ne 0) { throw 'Не удалось получить зависимости.' }
& flutter run -d emulator-5554

