@echo off
rem * GhettoRoot is licensed under GPLv3 or later. See file LICENSE.txt in root of package tree.
setlocal
pushd "%~dp0"
set PATH=%PATH%;%~dp0\..\tools
adb shell mkdir -p /data/local/tmp/ghetto/
adb push %~dp0\..\files /data/local/tmp/ghetto/ || (echo *** Could not push files. & exit /B 1)
adb shell "cd /data/local/tmp/ghetto; chmod 0755 ghettoroot busybox *.sh"
echo.
echo *** Necessary files pushed and chmod'd.
echo     Give it a brief moment or your device will be overwhelmed.
endlocal
popd
