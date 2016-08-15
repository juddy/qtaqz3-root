@echo off
rem * GhettoRoot is licensed under GPLv3 or later. See file LICENSE.txt in root of package tree.
setlocal
set PATH=%PATH%;%~dp0\..\tools
adb start-server
adb shell "rm -rf /data/local/tmp/ghetto" || (call :END & exit /B 1)
:END
if not "%1"=="1" adb kill-server
endlocal
