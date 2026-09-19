@echo off

setlocal

set SCRIPT_DIR=%~dp0
set HELPERS_DIR=%SCRIPT_DIR%..\.helpers

set COMMON_DLL=%SCRIPT_DIR%..\..\common\bin\common.dll
set CBHELPER_DLL=%SCRIPT_DIR%..\..\cbhelper\bin\cbhelper.dll

if not exist "%COMMON_DLL%" (
  echo ERROR: "%COMMON_DLL%" not found. Build the "common" project first.
  exit /b 1
)

if not exist "%CBHELPER_DLL%" (
  echo ERROR: "%CBHELPER_DLL%" not found. Build the "cbhelper" project first.
  exit /b 1
)

if not exist "%HELPERS_DIR%" mkdir "%HELPERS_DIR%"

copy /Y "%COMMON_DLL%" "%HELPERS_DIR%\" >nul
copy /Y "%CBHELPER_DLL%" "%HELPERS_DIR%\" >nul

echo Helper DLLs stored in "%HELPERS_DIR%".
echo You can now use the Debug setup.
pause

endlocal
