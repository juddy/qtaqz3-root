@echo off
rem * GhettoRoot is licensed under GPLv3 or later. See file LICENSE.txt in root of package tree.
setlocal
pushd "%~dp0"\..
set PATH=%PATH%;%~dp0\..\tools
set argC=0
set modstring=
for %%x in (%*) do set /A argC+=1
set v_params=%*
if 1 gtr %argC% (
  set v_params=
  if exist config.txt (
    set argC=0
    for /f "delims=" %%x in (config.txt) do (
      set /A argC+=1
      set v_params=%%x
    )
  )
) else (
  set v_params=%v_params:"=\"%
)
if exist modstring.txt (
  for /f "delims=" %%x in (modstring.txt) do (
    set modstring=-m "%%x" 
    goto escape_modstring
  )
)
goto skip_modstring
:escape_modstring
set modstring=%modstring:"=\"%
:skip_modstring
if 1 gtr %argC% set v_params=
echo.
adb shell "cd /data/local/tmp/ghetto; ./ghettoroot %modstring%%v_params%"
endlocal
popd
