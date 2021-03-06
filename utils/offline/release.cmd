@echo off
set APP_TITLE=KallistiOS Offline Packager for DreamSDK Setup
title %APP_TITLE%
cls

rem Initialization
set BASE_DIR=%~dp0
set BASE_DIR=%BASE_DIR:~0,-1%

set LOG_FILE=%BASE_DIR%\release.log
if exist %LOG_FILE% del %LOG_FILE%

call :log %APP_TITLE%
call :log

rem Read Configuration
set CONFIG_FILE=%BASE_DIR%\release.ini
for /F "tokens=*" %%i in (%CONFIG_FILE%) do (
	set %%i 2> nul
)

rem Sanitize configuration entries
call :trim PATCH
call :trim PYTHON
call :trim INPUT_DIR
call :trim OUTPUT_DIR

rem Utilities
set PYREPL="%PYTHON%" "%BASE_DIR%\data\pyrepl.py"

rem KallistiOS Directories
set LIB_INPUT_DIR=%INPUT_DIR%\lib
set LIB_OUTPUT_DIR=%OUTPUT_DIR%\lib

set KOS_INPUT_DIR=%LIB_INPUT_DIR%\kos
set KOS_OUTPUT_DIR=%LIB_OUTPUT_DIR%\kos
set KOS_PORTS_INPUT_DIR=%LIB_INPUT_DIR%\kos-ports
set KOS_PORTS_OUTPUT_DIR=%LIB_OUTPUT_DIR%\kos-ports
set DCLOAD_IP_INPUT_DIR=%LIB_INPUT_DIR%\dcload\dcload-ip
set DCLOAD_IP_OUTPUT_DIR=%LIB_OUTPUT_DIR%\dcload\dcload-ip
set DCLOAD_SER_INPUT_DIR=%LIB_INPUT_DIR%\dcload\dcload-serial
set DCLOAD_SER_OUTPUT_DIR=%LIB_OUTPUT_DIR%\dcload\dcload-serial

rem Ruby Directories
set RUBY_INPUT_DIR=%INPUT_DIR%\ruby
set RUBY_OUTPUT_DIR=%OUTPUT_DIR%\ruby

set RUBY_MRUBY_INPUT_DIR=%RUBY_INPUT_DIR%\mruby
set RUBY_MRUBY_OUTPUT_DIR=%RUBY_OUTPUT_DIR%\mruby
set RUBY_DREAMPRESENT_INPUT_DIR=%RUBY_INPUT_DIR%\samples\dreampresent
set RUBY_DREAMPRESENT_OUTPUT_DIR=%RUBY_OUTPUT_DIR%\samples\dreampresent
set RUBY_MRBTRIS_INPUT_DIR=%RUBY_INPUT_DIR%\samples\mrbtris
set RUBY_MRBTRIS_OUTPUT_DIR=%RUBY_OUTPUT_DIR%\samples\mrbtris

:start
pushd

if exist %KOS_OUTPUT_DIR% goto err_not_empty
if exist %KOS_PORTS_OUTPUT_DIR% goto err_not_empty
if exist %DCLOAD_IP_OUTPUT_DIR% goto err_not_empty
if exist %DCLOAD_SER_OUTPUT_DIR% goto err_not_empty
if exist %RUBY_OUTPUT_DIR% goto err_not_empty
if exist %RUBY_DREAMPRESENT_OUTPUT_DIR% goto err_not_empty
if exist %RUBY_MRBTRIS_OUTPUT_DIR% goto err_not_empty

rem Additional files
set KOS_ENVIRON=environ.sh

goto kos

rem KallistiOS
:kos
call :getver VERSION_KOS %KOS_INPUT_DIR%
call :log Processing: KallistiOS (%VERSION_KOS%)
call :copy %KOS_INPUT_DIR% %KOS_OUTPUT_DIR% %VERSION_KOS%
if exist %KOS_OUTPUT_DIR%\%KOS_ENVIRON% del %KOS_OUTPUT_DIR%\%KOS_ENVIRON%
call :setver "KallistiOS ##version##" "KallistiOS %VERSION_KOS%" "%KOS_OUTPUT_DIR%"
call :setver "relver='##version##'" "relver='%VERSION_KOS%'" "%KOS_OUTPUT_DIR%\kernel\arch\dreamcast\kernel"
call :setver "##version##" "%VERSION_KOS%" "%KOS_OUTPUT_DIR%\doc"
call :setver "##version##" "%VERSION_KOS%" "%KOS_OUTPUT_DIR%\kernel\arch\dreamcast\hardware\pvr"
goto kosports

rem KallistiOS Ports
:kosports
set KOS_PORTS_PATCH_DIR=%BASE_DIR%\data\kos-ports
set KOS_PORTS_UTILS_DIR=%KOS_PORTS_INPUT_DIR%\utils

call :getver VERSION_KOS_PORTS %KOS_PORTS_INPUT_DIR%
call :log Processing: KallistiOS Ports (%VERSION_KOS_PORTS%)

rem Download all KallistiOS Ports at once
call :patch %KOS_PORTS_INPUT_DIR% %KOS_PORTS_PATCH_DIR%\fetch.diff

rem Downloading all
set FETCH_ALL=%KOS_PORTS_UTILS_DIR%\fetch-all.sh
call :win2unix FETCH_ALL
cd /D %KOS_PORTS_UTILS_DIR%
%RUNNER% %FETCH_ALL% >> %LOG_FILE% 2>&1
call :wait

rem Copy everything
call :copy %KOS_PORTS_INPUT_DIR% %KOS_PORTS_OUTPUT_DIR% %VERSION_KOS_PORTS%
call :patch %KOS_PORTS_OUTPUT_DIR% %KOS_PORTS_PATCH_DIR%\offline.diff
call :patchreverse %KOS_PORTS_OUTPUT_DIR% %KOS_PORTS_PATCH_DIR%\fetch.diff
call :setver "kos-ports ##version##" "kos-ports %VERSION_KOS_PORTS%" "%KOS_PORTS_OUTPUT_DIR%"
call :setver "KallistiOS ##version##" "KallistiOS %VERSION_KOS_PORTS%" "%KOS_PORTS_OUTPUT_DIR%"
call :setver "KOS ##version##" "KOS %VERSION_KOS_PORTS%" "%KOS_PORTS_OUTPUT_DIR%"
goto dcload

rem Dreamcast-Tool
:dcload
mkdir %LIB_OUTPUT_DIR%\dcload
goto dcloadser

rem Dreamcast-Tool IP
:dcloadser
call :getver VERSION_DCLOAD_IP %DCLOAD_IP_INPUT_DIR%
call :log Processing: Dreamcast-Tool Internet Protocol (%VERSION_DCLOAD_IP%)
call :copy %DCLOAD_IP_INPUT_DIR% %DCLOAD_IP_OUTPUT_DIR% %VERSION_DCLOAD_IP%
goto dcloadip

rem Dreamcast-Tool Serial
:dcloadip
call :getver VERSION_DCLOAD_SERIAL %DCLOAD_SER_INPUT_DIR%
call :log Processing: Dreamcast-Tool Serial (%VERSION_DCLOAD_SERIAL%)
call :copy %DCLOAD_SER_INPUT_DIR% %DCLOAD_SER_OUTPUT_DIR% %VERSION_DCLOAD_SERIAL%
goto ruby

rem Ruby: mruby
:ruby
call :getver VERSION_RUBY %RUBY_MRUBY_INPUT_DIR%
call :log Processing: Ruby (%VERSION_RUBY%)
call :copy %RUBY_MRUBY_INPUT_DIR% %RUBY_MRUBY_OUTPUT_DIR% %VERSION_RUBY%
goto dreampresent

rem Ruby: dreampresent
:dreampresent
call :getver VERSION_DREAMPRESENT %RUBY_DREAMPRESENT_INPUT_DIR%
call :log Processing: Ruby Sample: DreamPresent (%VERSION_DREAMPRESENT%)
call :copy %RUBY_DREAMPRESENT_INPUT_DIR% %RUBY_DREAMPRESENT_OUTPUT_DIR% %VERSION_DREAMPRESENT%
goto mrbtris

rem Ruby: mrbtris
:mrbtris
call :getver VERSION_MRBTRIS %RUBY_MRBTRIS_INPUT_DIR%
call :log Processing: Ruby Sample: Mrbtris (%VERSION_MRBTRIS%)
call :copy %RUBY_MRBTRIS_INPUT_DIR% %RUBY_MRBTRIS_OUTPUT_DIR% %VERSION_MRBTRIS%
goto finish

:finish
call :log
call :log Done!
call :log
goto end

:end
popd
pause
goto :EOF

rem ## Errors ##################################################################

:err_not_empty
call :log Please cleanup the output directory.
call :log Output directory: '%OUTPUT_DIR%'.
goto end

rem ## Utilities ###############################################################

:trim
rem Thanks to: https://stackoverflow.com/a/19686956/3726096
setlocal EnableDelayedExpansion
call :trimsub %%%1%%
endlocal & set %1=%tempvar%
goto :EOF
:trimsub
set tempvar=%*
goto :EOF

:copy
set EXCLUDE_FILE=%BASE_DIR%\exclude.txt
echo .git\ > %EXCLUDE_FILE%
echo .svn\ >> %EXCLUDE_FILE%
xcopy %1\* %2 /exclude:%EXCLUDE_FILE% /s /i /y >> %LOG_FILE% 2>&1
if exist %EXCLUDE_FILE% del %EXCLUDE_FILE%
echo %3 > %2\OFFLINE
goto :EOF

:getver
set tmpgetver=(UNKNOWN)
set tmpverfile=%1.tmp
git -C "%2" describe --always --tags > %tmpverfile%
if not exist %tmpverfile% goto getverend
setlocal EnableDelayedExpansion
set /p tmpgetver=<%tmpverfile%
set tmpgetver=%tmpgetver%-offline
del %tmpverfile%
:getverend
endlocal & set %1=%tmpgetver%
goto :EOF

:setver
%PYREPL% %1 %2 %3%
goto :EOF

:win2unix
setlocal EnableDelayedExpansion
call :win2unixsub %%%1%%
set tmpwin2unix=%tmpwin2unix:\=/%
set tmpwin2unix=/%tmpwin2unix::=%
endlocal & set %1=%tmpwin2unix%
goto :EOF
:win2unixsub
set tmpwin2unix=%*
goto :EOF

:patch
%PATCH% -N -d %1 -p1 -r - < %2 >> %LOG_FILE% 2>&1
goto :EOF

:patchreverse
%PATCH% --reverse -N -d %1 -p1 -r - < %2 >> %LOG_FILE% 2>&1
goto :EOF

:log
set tmplog=%*
if "%tmplog%"=="" goto logempty
echo %tmplog%
echo %tmplog%>> %LOG_FILE% 2>&1
goto :EOF
:logempty
echo.
echo.>> %LOG_FILE% 2>&1
goto :EOF

:wait
%RUNNER% "sleep 3"
goto :EOF
