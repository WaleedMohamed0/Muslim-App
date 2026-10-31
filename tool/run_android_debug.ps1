param(
  [string]$DeviceId,
  [switch]$AllowFirstInstall
)

$ErrorActionPreference = 'Stop'

$adbCommand = Get-Command adb -ErrorAction Stop
$flutterCommand = Get-Command flutter -ErrorAction Stop
$deviceLines = & $adbCommand.Source devices
if ($LASTEXITCODE -ne 0) {
  throw 'adb devices failed. Check the Android SDK platform-tools installation.'
}

$connectedDeviceIds = @(
  $deviceLines |
    Select-Object -Skip 1 |
    Where-Object { $_ -match '^\S+\s+device$' } |
    ForEach-Object { ($_ -split '\s+')[0] }
)

if (-not $DeviceId) {
  if ($connectedDeviceIds.Count -ne 1) {
    throw "Connect exactly one Android device or pass -DeviceId. Connected devices: $($connectedDeviceIds -join ', ')"
  }
  $DeviceId = $connectedDeviceIds[0]
}

if ($connectedDeviceIds -notcontains $DeviceId) {
  throw "Android device '$DeviceId' is not connected and authorized in adb."
}

$applicationId = 'com.example.untitled8'
$installedApkResult = @(& $adbCommand.Source -s $DeviceId shell pm path $applicationId)
if ($LASTEXITCODE -ne 0 -or $installedApkResult.Count -eq 0) {
  if (-not $AllowFirstInstall) {
    throw "'$applicationId' is not installed on $DeviceId. Refusing to create a fresh install. Pass -AllowFirstInstall only when a first install is intended."
  }
  $installedApkPath = $null
} else {
  $installedApkPath = ($installedApkResult[0] -replace '^package:', '').Trim()
}

Write-Host 'Building one arm64 debug APK. No uninstall, clean, or app-data wipe will be run.'
& $flutterCommand.Source build apk --debug --no-pub --target-platform android-arm64
if ($LASTEXITCODE -ne 0) {
  throw 'Flutter build failed; the device installation was not touched.'
}

$apkPath = Join-Path $PSScriptRoot '..\build\app\outputs\flutter-apk\app-debug.apk'
$apkPath = [System.IO.Path]::GetFullPath($apkPath)
if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
  throw "Expected debug APK was not produced: $apkPath"
}

if ($installedApkPath) {
  $androidSdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
  $buildTools = Get-ChildItem (Join-Path $androidSdk 'build-tools') -Directory -ErrorAction Stop |
    Sort-Object { try { [version]$_.Name } catch { [version]'0.0' } } -Descending |
    Select-Object -First 1
  $apksigner = Join-Path $buildTools.FullName 'apksigner.bat'
  if (-not (Test-Path -LiteralPath $apksigner -PathType Leaf)) {
    throw 'Android build-tools apksigner was not found; refusing an unchecked install.'
  }

  $pulledApkPath = Join-Path ([System.IO.Path]::GetTempPath()) ("muslim-installed-$([guid]::NewGuid().ToString('N')).apk")
  try {
    & $adbCommand.Source -s $DeviceId pull $installedApkPath $pulledApkPath | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not read the installed APK certificate for comparison.' }

    $installedCertOutput = & $apksigner verify --print-certs $pulledApkPath 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw 'Could not verify the installed APK certificate.' }
    $builtCertOutput = & $apksigner verify --print-certs $apkPath 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw 'Could not verify the new APK certificate.' }

    $certPattern = 'Signer #\d+ certificate SHA-256 digest:\s*([0-9a-fA-F]+)'
    $installedCert = [regex]::Match($installedCertOutput, $certPattern).Groups[1].Value
    $builtCert = [regex]::Match($builtCertOutput, $certPattern).Groups[1].Value
    if (-not $installedCert -or -not $builtCert) {
      throw 'Unable to compare APK signing certificates; refusing an unchecked install.'
    }
    if ($installedCert -ne $builtCert) {
      throw 'The installed app and new APK use different signing certificates. The app was left untouched; restore the original signing key before updating.'
    }
  } finally {
    if (Test-Path -LiteralPath $pulledApkPath) {
      Remove-Item -LiteralPath $pulledApkPath -Force
    }
  }
}

& $adbCommand.Source -s $DeviceId install -r $apkPath
if ($LASTEXITCODE -ne 0) {
  throw 'ADB refused the update. The script did not uninstall the existing app or clear its data.'
}

& $adbCommand.Source -s $DeviceId shell am start -n "$applicationId/.MainActivity"
if ($LASTEXITCODE -ne 0) { throw 'APK installed, but the app could not be launched.' }

Write-Host 'App updated. Attaching Flutter for hot reload; press r for reload, R for restart, or q to detach.'
& $flutterCommand.Source attach -d $DeviceId
exit $LASTEXITCODE
