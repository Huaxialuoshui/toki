# Toki 一键打包（Android APK + Windows 免安装包 + Windows 安装包）
#
# 由 package.bat 调用：
#   package.bat [all|apk|windows] [check] [nopause]
# 也可以直接跑：
#   powershell -ExecutionPolicy Bypass -File tool\package.ps1 windows
#
# 所有输出同时写进 package.log；出错会说明原因和下一步怎么做。

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# 控制台按 UTF-8 输出（launcher 里已经 chcp 65001），这样中文在控制台、管道、
# 日志三处都不会变乱码。
try {
    # 直接跑这个脚本（不经过 package.bat）时，也自己把控制台切到 UTF-8。
    & chcp.com 65001 > $null
} catch {
    # chcp 不可用就算了，下面的 OutputEncoding 仍然生效。
}
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # 某些宿主（比如 ISE）不允许改，忽略即可。
}

$Root = Split-Path -Parent $PSScriptRoot          # tool\ 的上一级 = 项目根
$LogPath = Join-Path $Root 'package.log'
$Mode = 'all'
$RunCheck = $false

function Write-Log {
    param([string]$Message = '', [string]$Color)
    if ($Color) { Write-Host $Message -ForegroundColor $Color } else { Write-Host $Message }
    Add-Content -LiteralPath $LogPath -Value $Message -Encoding UTF8
}

function Fail {
    param([string]$Message)
    Write-Log ''
    Write-Log "[x] $Message" 'Red'
    Write-Log ''
    Write-Log '  常见原因：'
    Write-Log '    * Android：android\key.properties / toki-release.jks 缺失，或没接受 Android SDK 许可'
    Write-Log '    * Windows：没装 Visual Studio 的「使用 C++ 的桌面开发」工作负载'
    Write-Log '    * 网络：Gradle / pub 拉包失败，重跑一次通常会好'
    Write-Log "  完整日志：$LogPath"
    exit 1
}

# 跑一条命令：输出逐行实时打屏 + 写进日志，返回退出码。
function Invoke-Tool {
    param([string]$Exe, [string[]]$ToolArgs)
    & $Exe @ToolArgs 2>&1 | ForEach-Object {
        $line = if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.ToString() } else { "$_" }
        Write-Host $line
        Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
    }
    return $LASTEXITCODE
}

function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1MB) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }
    return ('{0:N0} KB' -f ($Bytes / 1KB))
}

foreach ($a in $args) {
    switch -Regex ($a) {
        '^(?i)apk$' { $Mode = 'apk'; continue }
        '^(?i)windows$' { $Mode = 'windows'; continue }
        '^(?i)all$' { $Mode = 'all'; continue }
        '^(?i)check$' { $RunCheck = $true; continue }
        default { }
    }
}

Write-Log ''
Write-Log '==========================================================='
Write-Log '  Toki 打包脚本'
Write-Log '==========================================================='
Write-Log "[环境] PowerShell $($PSVersionTable.PSVersion)  项目目录：$Root"

# --- 1. 找 Flutter --------------------------------------------------------
$flutter = $null
$found = Get-Command 'flutter' -ErrorAction SilentlyContinue
if ($found) { $flutter = $found.Source }
if (-not $flutter -and $env:FLUTTER_ROOT) {
    $candidate = Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat'
    if (Test-Path $candidate) { $flutter = $candidate }
}
foreach ($candidate in @('D:\Flutter\flutter\bin\flutter.bat', 'C:\Flutter\flutter\bin\flutter.bat')) {
    if (-not $flutter -and (Test-Path $candidate)) { $flutter = $candidate }
}
if (-not $flutter) {
    Fail '没找到 flutter。请把 Flutter 的 bin 目录加进 PATH，或用 set FLUTTER_ROOT=D:\Flutter\flutter 指定 SDK。'
}
Write-Log "[1/6] Flutter：$flutter"
& $flutter --version 2>&1 | Select-Object -First 1 | ForEach-Object { Write-Log "      $_" }

# --- 2. 版本号 ------------------------------------------------------------
$versionMatch = (Select-String -Path (Join-Path $Root 'pubspec.yaml') -Pattern '^version:\s*(\S+)').Matches
if (-not $versionMatch -or $versionMatch.Count -eq 0) { Fail '没能从 pubspec.yaml 里读到 version。' }
$VersionFull = $versionMatch[0].Groups[1].Value
$Version = ($VersionFull -split '\+')[0]
Write-Log "[2/6] 版本：$VersionFull（文件名用 $Version）"

$Dist = Join-Path $Root 'dist'
if (-not (Test-Path $Dist)) { New-Item -ItemType Directory -Path $Dist | Out-Null }
$ApkOut = Join-Path $Dist "Toki-$Version-android.apk"
$ZipOut = Join-Path $Dist "Toki-$Version-windows-x64.zip"
$SetupOut = Join-Path $Dist "Toki-$Version-windows-x64-setup.exe"
$PortableDir = Join-Path $Dist "Toki-$Version-windows-x64"

# --- 3. 可选：analyze + test ---------------------------------------------
if ($RunCheck) {
    Write-Log '[3/6] flutter analyze ...'
    if ((Invoke-Tool $flutter @('analyze')) -ne 0) { Fail 'flutter analyze 没过。' }
    Write-Log '      flutter test ...'
    if ((Invoke-Tool $flutter @('test')) -ne 0) { Fail 'flutter test 没过。' }
} else {
    Write-Log '[3/6] 跳过 analyze / test（想跑就加参数：package.bat check）'
}
Write-Log '      flutter pub get ...'
if ((Invoke-Tool $flutter @('pub', 'get')) -ne 0) { Fail 'flutter pub get 失败。' }

# --- 4. Android APK -------------------------------------------------------
if ($Mode -eq 'windows') {
    Write-Log '[4/6] 跳过 Android（只打 Windows）'
} else {
    Write-Log '[4/6] 打包 Android APK（release，正式签名）...'
    if (-not (Test-Path (Join-Path $Root 'android\key.properties'))) {
        Write-Log '      [!] 没有 android\key.properties，会用 debug 签名 —— 装到手机上会和正式签名版冲突。' 'Yellow'
    }
    if ((Invoke-Tool $flutter @('build', 'apk', '--release')) -ne 0) { Fail 'flutter build apk --release 失败。' }
    $apk = Join-Path $Root 'build\app\outputs\flutter-apk\app-release.apk'
    if (-not (Test-Path $apk)) { Fail "没找到 $apk。" }
    Copy-Item -LiteralPath $apk -Destination $ApkOut -Force
    Write-Log "      -> $ApkOut"
}

# --- 5. Windows 免安装包 -------------------------------------------------
$ReleaseDir = Join-Path $Root 'build\windows\x64\runner\Release'
if ($Mode -eq 'apk') {
    Write-Log '[5/6] 跳过 Windows（只打 APK）'
} else {
    Write-Log '[5/6] 打包 Windows（release）...'
    if ((Invoke-Tool $flutter @('build', 'windows', '--release')) -ne 0) { Fail 'flutter build windows --release 失败。' }
    if (-not (Test-Path (Join-Path $ReleaseDir 'toki.exe'))) { Fail "没找到 $ReleaseDir\toki.exe，构建似乎没成功。" }

    Write-Log "      复制到 $PortableDir ..."
    # robocopy 的 0-7 都算成功（1=复制了文件、2=有额外文件、3=两者都有）
    & robocopy $ReleaseDir $PortableDir /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { Fail "复制文件失败（robocopy 退出码 $LASTEXITCODE）。" }
    $global:LASTEXITCODE = 0

    Write-Log '      压缩成 zip ...'
    if (Test-Path $ZipOut) { Remove-Item -LiteralPath $ZipOut -Force }
    Compress-Archive -Path (Join-Path $ReleaseDir '*') -DestinationPath $ZipOut -Force
    Write-Log "      -> $ZipOut"
}

# --- 6. Windows 安装包（内嵌 payload，用系统自带 csc 编译）---------------
if ($Mode -eq 'apk') {
    Write-Log '[6/6] 跳过安装包（只打 APK）'
} else {
    $csc = $null
    foreach ($candidate in @(
            (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
            (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'))) {
        if (-not $csc -and (Test-Path $candidate)) { $csc = $candidate }
    }
    if (-not $csc) {
        Write-Log '[6/6] [!] 这台机器上没有 .NET Framework 的 csc.exe，跳过安装包；免安装 zip 已经好了。' 'Yellow'
    } else {
        Write-Log '[6/6] 生成 Windows 安装包（内嵌 release 目录）...'
        $work = Join-Path $Root 'build\installer'
        if (-not (Test-Path $work)) { New-Item -ItemType Directory -Path $work | Out-Null }
        $payload = Join-Path $work 'payload.zip'
        $setupCs = Join-Path $work 'setup.cs'

        if (Test-Path $payload) { Remove-Item -LiteralPath $payload -Force }
        Compress-Archive -Path (Join-Path $ReleaseDir '*') -DestinationPath $payload -Force

        # 模板里的 @VERSION@ 换成真实版本号；写成带 BOM 的 UTF-8，csc 才能正确读中文
        $source = Get-Content -LiteralPath (Join-Path $Root 'tool\installer\setup.cs.in') -Raw
        $source = $source.Replace('@VERSION@', $Version)
        [System.IO.File]::WriteAllText($setupCs, $source, (New-Object System.Text.UTF8Encoding($true)))

        $icon = Join-Path $Root 'windows\runner\resources\app_icon.ico'
        $cscArgs = @(
            '/nologo', '/target:winexe', '/platform:anycpu', '/optimize+',
            "/out:$SetupOut",
            "/resource:$payload,payload.zip",
            '/reference:System.dll,System.Drawing.dll,System.Windows.Forms.dll,System.IO.Compression.dll,Microsoft.CSharp.dll',
            $setupCs
        )
        if (Test-Path $icon) { $cscArgs = @("/win32icon:$icon") + $cscArgs }
        if (Test-Path $SetupOut) { Remove-Item -LiteralPath $SetupOut -Force }
        if ((Invoke-Tool $csc $cscArgs) -ne 0) { Fail '编译安装包失败（csc 报错见上方）。' }
        if (-not (Test-Path $SetupOut)) { Fail 'csc 没有产出安装包。' }
        Write-Log "      -> $SetupOut"
    }
}

# --- 汇总 ----------------------------------------------------------------
Write-Log ''
Write-Log '==========================================================='
Write-Log "  打包完成（版本 $Version），产物在 dist\："
Write-Log '==========================================================='
foreach ($file in @($ApkOut, $ZipOut, $SetupOut)) {
    if (Test-Path $file) {
        $item = Get-Item -LiteralPath $file
        Write-Log ("  {0}   {1}" -f $item.Name, (Format-Size $item.Length))
    }
}
if (Test-Path $PortableDir) { Write-Log "  $(Split-Path -Leaf $PortableDir)\   （免安装目录，可整个拷走）" }
Write-Log ''
Write-Log '  手机：把 apk 拷过去安装（首次要允许"未知来源"）。'
Write-Log '  电脑：免安装就解压 zip（整个目录一起，别只拷 exe）；要装进系统就用 setup.exe。'
Write-Log ''
Write-Log '  安装包支持静默 / 换目录 / 卸载：'
Write-Log '    setup.exe /silent /dir=D:\Apps\Toki /noshortcuts /noregistry'
Write-Log '    setup.exe /uninstall /silent'
Write-Log ''
exit 0
