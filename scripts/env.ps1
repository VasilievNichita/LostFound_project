$env:TEMP = 'D:\PAM\tmp'
$env:TMP = $env:TEMP
$env:PUB_CACHE = 'D:\PAM\cache\pub'
$env:GRADLE_USER_HOME = 'D:\PAM\cache\gradle'
$env:ANDROID_HOME = 'D:\PAM\tools\android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = 'D:\PAM\profile\android'
$env:ANDROID_EMULATOR_HOME = $env:ANDROID_USER_HOME
$env:ANDROID_AVD_HOME = 'D:\PAM\profile\avd'
$env:ADB_VENDOR_KEYS = 'D:\PAM\profile\android'
$env:JAVA_HOME = 'D:\PAM\tools\android-studio\jbr'
$env:USERPROFILE = 'D:\PAM\profile'
$env:APPDATA = 'D:\PAM\profile\AppData\Roaming'
$env:LOCALAPPDATA = 'D:\PAM\profile\AppData\Local'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:CI = 'true'
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'safe.directory'
$env:GIT_CONFIG_VALUE_0 = 'D:/PAM/tools/flutter'
$env:JAVA_TOOL_OPTIONS = '-Duser.home=D:\PAM\profile -Djava.io.tmpdir=D:\PAM\tmp'
$env:PYTHONIOENCODING = 'utf-8'
$env:Path = "D:\PAM\tools\flutter\bin;D:\PAM\tools\android-sdk\platform-tools;D:\PAM\tools\android-sdk\cmdline-tools\latest\bin;$env:JAVA_HOME\bin;C:\Program Files\Git\cmd;$env:Path"
@($env:TEMP,$env:PUB_CACHE,$env:GRADLE_USER_HOME,$env:ANDROID_USER_HOME,$env:ANDROID_AVD_HOME,$env:APPDATA,$env:LOCALAPPDATA) | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }
