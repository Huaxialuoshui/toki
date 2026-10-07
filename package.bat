@echo off
chcp 65001 >nul
rem ===========================================================================
rem  Toki packaging launcher.
rem
rem  This file is intentionally ASCII-only: it does nothing but call
rem  tool\package.ps1 (all the real work and the Chinese messages live there,
rem  so a code-page mismatch can never break parsing of this file).
rem
rem  Usage:  package.bat [all^|apk^|windows] [check] [nopause]
rem  Always writes package.log next to this file.
rem ===========================================================================
setlocal
set "ROOT=%~dp0"
set "LOG=%ROOT%package.log"

rem --- keep the console window open unless the caller passed "nopause" ------
set "NOPAUSE="
for %%a in (%*) do (
  if /i "%%~a"=="nopause" set "NOPAUSE=1"
)

cd /d "%ROOT%" 2>nul

echo ===========================================================
echo   Toki packaging - starting
echo   project : %ROOT%
echo   log     : %LOG%
echo ===========================================================
echo.

rem Seed the log so it exists even if PowerShell itself cannot start.
> "%LOG%" echo === Toki packaging log ===
>>"%LOG%" echo project=%ROOT%
>>"%LOG%" echo time=%TIME%
>>"%LOG%" echo args=%*

set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS%" set "PS=powershell"

call "%PS%" -NoProfile -ExecutionPolicy Bypass -File "%ROOT%tool\package.ps1" %*
set "CODE=%ERRORLEVEL%"

echo.
if not "%CODE%"=="0" (
  echo ===========================================================
  echo   PACKAGING FAILED  (exit code %CODE%)
  echo   Full log: %LOG%
  echo ===========================================================
) else (
  echo ===========================================================
  echo   PACKAGING DONE - see dist\
  echo   Full log: %LOG%
  echo ===========================================================
)
echo.
if not defined NOPAUSE pause
exit /b %CODE%
