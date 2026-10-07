@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d "%~dp0"

rem ===========================================================================
rem  Toki 一键打包：Android APK + Windows 免安装包 + Windows 安装包
rem
rem  用法：
rem    package.bat                 打包 APK + Windows（zip + setup.exe）
rem    package.bat apk             只打包 APK
rem    package.bat windows         只打包 Windows
rem    package.bat check           打包前先跑 flutter analyze + flutter test
rem    package.bat check nopause   组合使用（nopause = 结束不等待按键）
rem
rem  产物：dist\Toki-<版本>-android.apk
rem        dist\Toki-<版本>-windows-x64.zip        （免安装，解压即用）
rem        dist\Toki-<版本>-windows-x64-setup.exe  （安装包，自带卸载）
rem  说明：安装包用系统自带的 .NET 编译器生成，不需要 Inno Setup / NSIS 等第三方工具。
rem ===========================================================================

set "MODE=all"
set "RUN_CHECK=0"
set "PAUSE_AT_END=1"

:parse_args
if "%~1"=="" goto args_done
set "ARG=%~1"
if /i "!ARG!"=="apk" set "MODE=apk"
if /i "!ARG!"=="windows" set "MODE=windows"
if /i "!ARG!"=="all" set "MODE=all"
if /i "!ARG!"=="check" set "RUN_CHECK=1"
if /i "!ARG!"=="nopause" set "PAUSE_AT_END=0"
shift
goto parse_args
:args_done

echo.
echo ===========================================================
echo   Toki 打包脚本
echo ===========================================================

rem --- 1. 找 Flutter -------------------------------------------------------
set "FLUTTER="
where flutter >nul 2>nul && set "FLUTTER=flutter"
if not defined FLUTTER if exist "D:\Flutter\flutter\bin\flutter.bat" set "FLUTTER=D:\Flutter\flutter\bin\flutter.bat"
if not defined FLUTTER if defined FLUTTER_ROOT if exist "%FLUTTER_ROOT%\bin\flutter.bat" set "FLUTTER=%FLUTTER_ROOT%\bin\flutter.bat"
if not defined FLUTTER (
  echo [x] 没找到 flutter。请把 Flutter 的 bin 目录加进 PATH，
  echo     或者用 "set FLUTTER_ROOT=D:\Flutter\flutter" 指定 SDK 位置。
  goto fail
)
echo [1/6] Flutter：!FLUTTER!
for /f "delims=" %%v in ('call "!FLUTTER!" --version ^| findstr /b "Flutter"') do echo       %%v

rem --- 2. 读版本号 --------------------------------------------------------
set "VER_FULL="
for /f "usebackq tokens=1,2" %%a in (`findstr /b /c:"version:" pubspec.yaml`) do set "VER_FULL=%%b"
if not defined VER_FULL (
  echo [x] 没能从 pubspec.yaml 里读到 version。
  goto fail
)
for /f "tokens=1 delims=+" %%v in ("!VER_FULL!") do set "VER=%%v"
echo [2/6] 版本：!VER_FULL!  （打包文件名用 !VER!）
if not exist "dist" mkdir "dist"

rem --- 3. 可选：静态检查 + 测试 ------------------------------------------
if "%RUN_CHECK%"=="1" (
  echo [3/6] flutter analyze ...
  call "!FLUTTER!" analyze || goto fail
  echo       flutter test ...
  call "!FLUTTER!" test || goto fail
) else (
  echo [3/6] 跳过 analyze / test（想跑就加参数：package.bat check）
)

echo       flutter pub get ...
call "!FLUTTER!" pub get || goto fail

rem --- 4. Android APK ----------------------------------------------------
if /i "%MODE%"=="windows" goto skip_apk
echo [4/6] 打包 Android APK（release，正式签名）...
if not exist "android\key.properties" (
  echo       [!] 没有 android\key.properties，会用 debug 签名——这种包装到手机上
  echo           跟之前的正式签名版冲突。要出正式包请补上签名配置。
)
call "!FLUTTER!" build apk --release || goto fail
copy /y "build\app\outputs\flutter-apk\app-release.apk" "dist\Toki-!VER!-android.apk" >nul || goto fail
goto after_apk
:skip_apk
echo [4/6] 跳过 Android（只打 Windows）
:after_apk

rem --- 5. Windows 免安装包 ------------------------------------------------
if /i "%MODE%"=="apk" goto skip_windows
echo [5/6] 打包 Windows（release）...
call "!FLUTTER!" build windows --release || goto fail
set "REL=build\windows\x64\runner\Release"
if not exist "!REL!\toki.exe" (
  echo [x] 没找到 !REL!\toki.exe，构建似乎没成功。
  goto fail
)
echo       复制到 dist\Toki-!VER!-windows-x64 ...
robocopy "!REL!" "dist\Toki-!VER!-windows-x64" /MIR /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (
  echo [x] 复制文件失败（robocopy 错误码 !errorlevel!）。
  goto fail
)
echo       压缩成 zip ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Compress-Archive -Path '!REL!\*' -DestinationPath 'dist\Toki-!VER!-windows-x64.zip' -Force" || goto fail
goto after_windows
:skip_windows
echo [5/6] 跳过 Windows（只打 APK）
:after_windows

rem --- 6. Windows 安装包（内嵌 payload，用系统自带 csc 编译）-------------
if /i "%MODE%"=="apk" goto done

set "CSC="
for %%p in (
  "%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
  "%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
) do if not defined CSC if exist %%p set "CSC=%%~p"

if not defined CSC (
  echo [6/6] [!] 这台机器上没找到 .NET Framework 的 csc.exe，跳过安装包生成。
  echo           免安装 zip 已经好了，解压就能用。
  goto done
)

echo [6/6] 生成 Windows 安装包（内嵌 !VER! 的 release 目录）...
if not exist "build\installer" mkdir "build\installer"
if exist "build\installer\payload.zip" del /q "build\installer\payload.zip"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Compress-Archive -Path 'build\windows\x64\runner\Release\*' -DestinationPath 'build\installer\payload.zip' -Force" || goto fail

rem 把版本号写进安装程序源码（带 BOM 的 UTF-8，csc 才能正确读中文）
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$src = Get-Content -Raw 'tool\installer\setup.cs.in';" ^
  "$src = $src -replace '@VERSION@','!VER!';" ^
  "Set-Content -Path 'build\installer\setup.cs' -Value $src -Encoding UTF8" || goto fail

set "ICON_OPT="
if exist "windows\runner\resources\app_icon.ico" set "ICON_OPT=/win32icon:windows\runner\resources\app_icon.ico"

"!CSC!" /nologo /target:winexe /platform:anycpu /optimize+ /nowarn:1591 ^
  /out:"dist\Toki-!VER!-windows-x64-setup.exe" ^
  !ICON_OPT! ^
  /resource:"build\installer\payload.zip",payload.zip ^
  /reference:System.dll,System.Drawing.dll,System.Windows.Forms.dll,System.IO.Compression.dll,Microsoft.CSharp.dll ^
  "build\installer\setup.cs" || goto fail
if not exist "dist\Toki-!VER!-windows-x64-setup.exe" goto fail

:done
echo.
echo ===========================================================
echo   打包完成，产物在 dist\：
echo ===========================================================
for %%f in ("dist\Toki-!VER!-android.apk" "dist\Toki-!VER!-windows-x64.zip" "dist\Toki-!VER!-windows-x64-setup.exe") do (
  if exist %%f (
    for %%s in (%%f) do echo   %%~nxf   %%~zs 字节
  )
)
echo.
echo   手机：把 apk 拷过去安装（首次要允许"未知来源"）。
echo   电脑：懒得装就用 zip（整个目录解压，别只拷 exe）；
echo         要装到系统里就用 setup.exe（带桌面快捷方式与卸载项）。
echo.
echo   安装包支持静默/换目录：
echo     setup.exe /silent /dir=D:\Apps\Toki /noshortcuts /noregistry
echo     setup.exe /uninstall /silent
echo.
if "%PAUSE_AT_END%"=="1" pause
exit /b 0

:fail
echo.
echo [x] 打包中断了。上面的报错就是原因；常见坑：
echo     * Android：android\key.properties / toki-release.jks 缺失，或没接受 SDK 许可
echo     * Windows：没装 Visual Studio 的"使用 C++ 的桌面开发"工作负载
echo     * 网络：Gradle / pub 下载失败，重跑一次通常会好
echo.
if "%PAUSE_AT_END%"=="1" pause
exit /b 1
