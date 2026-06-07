$ErrorActionPreference = 'SilentlyContinue'

$envKey = 'HKCU:\Environment'
$h = (Get-ItemProperty -Path $envKey -Name ANDROID_HOME).ANDROID_HOME
$r = (Get-ItemProperty -Path $envKey -Name ANDROID_SDK_ROOT).ANDROID_SDK_ROOT
$p = (Get-ItemProperty -Path $envKey -Name Path).Path

$sdkMgr = 'C:\Android\cmdline-tools\latest\bin\sdkmanager.bat'

$result = [ordered]@{
  ANDROID_HOME = $h
  ANDROID_SDK_ROOT = $r
  sdkmanager_path = $sdkMgr
  sdkmanager_present = (Test-Path $sdkMgr)
  user_path = $p
  path_has_cmdline_bin = ($p -match [regex]::Escape('C:\Android\cmdline-tools\latest\bin'))
  path_has_platform_tools = ($p -match [regex]::Escape('C:\Android\platform-tools'))
  path_has_emulator = ($p -match [regex]::Escape('C:\Android\emulator'))
}

$result | ConvertTo-Json | Out-File -Encoding utf8 .\.tmp-verify.json
Write-Host "VERIFY_DONE"
