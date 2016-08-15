@echo off
rem * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
rem *  This file is part of GhettoRoot.                                       *
rem *                                                                         *
rem *  GhettoRoot is free software: you can redistribute it and/or modify     *
rem *  it under the terms of the GNU General Public License as published by   *
rem *  the Free Software Foundation, either version 3 of the License, or      *
rem *  (at your option) any later version.                                    *
rem *                                                                         *
rem *  GhettoRoot is distributed in the hope that it will be useful,          *
rem *  but WITHOUT ANY WARRANTY; without even the implied warranty of         *
rem *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
rem *  GNU General Public License for more details.                           *
rem *                                                                         *
rem *  You should have received a copy of the GNU General Public License      *
rem *  along with GhettoRoot.  If not, see <http://www.gnu.org/licenses/>.    *
rem * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
setlocal
pushd "%~dp0"
set TOOLSCOPIED=
set TRYAGAIN=1
set TRIEDONCE=
set OLDPATH=%PATH%
set PATH=%~dp0\scripts;%OLDPATH%;%~dp0\tools\win\curl;%~dp0\tools\win\adb;%~dp0\tools\win
echo ---- GhettoRoot Installer ----
goto TOP2
:TOP
set PATH=%~dp0\scripts;%~dp0\tools\win\curl;%~dp0\tools\win\adb;%~dp0\tools\win;%OLDPATH%
:TOP2
  if not exist files\busybox (
    if not exist files\busybox-armv4tl (
      if exist busybox (
        move busybox files\busybox
      ) else (
        if exist busybox-armv4tl (
          move busybox-armv4tl files\busybox
        ) else (
          goto NO_BUSYBOX
        )
      )
    ) else (
      move files\busybox-armv4tl files\busybox
    )
  )
  echo   Can we start up ADB?
:DO_START
  adb start-server && (echo   Yes!) || (goto CANNOT_START)
  echo.
  echo   Can a device be found?
:DO_FIND
  adb start-server >NUL 2>NUL
  for /F %%C in ('adb devices ^| "%SYSTEMROOT%\system32\find.exe" /V /C "List of devices attached"') do if %%C GTR 1 (echo   Yes!) else (goto CANNOT_FIND)
  echo.
  echo   Can we communicate with a device?
:DO_SHELL
  set devicemsg=  Yes! (This message came from your device.)
  for /F "delims=" %%C in ('adb shell echo "%devicemsg%" 2^>^&1 ^|^| SET msgerr^=1') do (
    SET msg=%%C
  )
  if not "%msg%"=="%devicemsg%" goto CANNOT_SHELL
  echo %msg%
:DO_PROCESS
  echo.
  echo * READ the README.txt file before continuing.
  echo *** Please wait until your device is out of Installer mode before continuing.
  echo     You can tell by looking at the USB mode in your Notifications.
  echo     Your device automatically switches out of Installer in about 30 seconds.
  echo     If you aren't sure, just wait 30 seconds and then press Y.
  echo.
:ASK_OUT_OF_INSTALLER
  set /P response=    Is your device OUT of INSTALLER mode? ^(Y/N^) 
  if "%response%"=="y" goto OUT_OF_INSTALLER
  if "%response%"=="Y" goto OUT_OF_INSTALLER
  if not "%response%"=="N" if not "%response%"=="n" (echo   Please enter Y or N. & goto ASK_OUT_OF_INSTALLER)
  echo.
  echo *** Well, please wait as instructed, and then relaunch the process.
  echo     I don't want to damage your device.
  echo *** You may say Y to this next time if your device does not have
  echo     an Installer mode.
  echo     If you aren't sure, just wait 30 seconds next time and then press Y.
  goto ABORT
  pause >NUL
:OUT_OF_INSTALLER
  echo.
  echo * WARNING: This process may void your warranty or cause unexpected damage
  echo * to your device. By using this software, you are accepting these risks.
  echo.
  echo * This is your last chance to back out!
  echo * Please ensure your phone does not have any busy apps running!
  echo.
:DO_PROCESS_ASK
  set /P response=   Continue? ^(Y/N^) 
  if "%response%"=="N" goto ABORT
  if "%response%"=="n" goto ABORT
  if not "%response%"=="Y" if not "%response%"=="y" goto DO_PROCESS_ASK
  echo.
  del /Q debug.txt >NUL 2>&1
  (call clean.cmd 1 2>&1 && (echo. &echo * Cleaned!) || (echo. &echo * Not cleaned, but no biggie.)) | wtee debug.txt
  echo.
  (call prepare.cmd 1 2>&1 && (echo. &echo  * Preparation files transferred!) || (echo. &echo *** Could not send preparation files! & goto END)) | wtee -a debug.txt
  echo.
  (call ghettoroot.cmd %* 2>&1 || (echo. &echo *** Script returned an error... Did it fail?)) | wtee -a debug.txt
  echo.
  echo *** ghettoroot execution completed! Investigate the results...
  echo.
  echo * All that's left is a bit of cleanup, or press N to end this.
  echo.
  set /P response=Clean up? ^([Y]/N^) 
  if not "%response%"=="Y" if not "%response%"=="y" if not "%response%"=="" goto SUCCESS
  echo.
  echo   When your device has restarted (if applicable), press any key to clean
  echo     out the temporary files on your device that were used for the rooting
  echo     process and are located at /data/local/tmp/ghetto.
  echo   This is optional. The important stuff is done!
  echo.
  pause
  echo.
  echo UNLOCK your device when it is started up again, before continuing.
  echo.
  pause
:CLEAN
  call clean.cmd 2>&1 && goto SUCCESS
  echo.
  echo * Could not clean temporary files, but that's not so bad.
:TRY_CLEAN_AGAIN
  set /P response=Try cleaning again? ^(Y/[N]^) 
  if "%response%"=="n" goto SUCCESS
  if "%response%"=="N" goto SUCCESS
  if "%response%"=="" goto SUCCESS
  if not "%response%"=="Y" if not "%response%"=="y" goto TRY_CLEAN_AGAIN
  echo.
  goto CLEAN
:CANNOT_START
  echo * Please install the Android SDK, or place adb.exe in the tools\
  echo   folder, and try again.
  echo * If you have already installed the SDK, check your PATH variable
  echo   in Start, Run, sysdm.cpl, Advanced, Environment Variables and make
  echo   sure that the SDK's platform-tools subdirectory is in, at least,
  echo   your user PATH environment variable. Create a new PATH variable
  echo   if necessary. Check the Android SDK installation instructions
  echo   for more information.
  echo.
  if "%TOOLSCOPIED%"=="" (call :COPY_TOOLS & goto DO_START)
  goto END
:CANNOT_FIND
  if not "%TRIEDONCE%"=="" if "%TOOLSCOPIED%"=="" (echo   No. & echo. & call :COPY_TOOLS & goto DO_FIND)
  echo   No. Cannot see your Android device.
  echo.
  echo *** USB CONNECTION CHECKLIST: (1/2)
  echo.
  echo * Have you unlocked your device on the lockscreen?
  echo.
  echo * Have you tried switching USB modes via the USB notification?
  echo   - Try toggling between Camera and MTP mode.
  echo.
  echo * Is your device actually plugged in?
  echo.
  echo * Have you downloaded and installed the proper drivers?
  echo   - Try searching for and using: Koush Universal ADB driver
  echo.
  echo * Have you enabled USB debugging?  Sometimes it gets disabled!
  echo   - You can enable this by going to Settings, About device on your
  echo     device and tapping Build number several times. Then, go Back,
  echo     enter Developer options, and check to enable USB debugging.
  echo.
  pause
  echo.
  echo *** USB CONNECTION CHECKLIST: (2/2)
  echo.
  echo * Have you authorized your PC to debug your device?
  echo   - You should have received a dialog on your device prompting you to
  echo     allow your computer to make a connection, but this doesn't always
  echo     happen. If you don't, try going to Developer options and tapping
  echo     Revoke USB authorization, then disable and re-enable debugging,
  echo     and then choose to Allow your computer. If that still doesn't
  echo     help, reconnect your device and try again.
  echo.
  echo * Is nothing working so far?
  echo   - One other thing to try is to access a hidden menu on your device
  echo     to change USB settings. Sometimes this helps. See below.
  echo.
  echo   - On the Verizon Galaxy Note 2 with 4.4.2 firmware, you can enter
  echo     ##366633# and then try switching back and forth between Enable
  echo     and Disable DM Mode, reconnecting your device and/or toggling
  echo     USB debugging in between. This is a last-ditch effort, but it
  echo     might help.
  echo.
  echo   - Remember that USSD code and the original Enable/Disable value so
  echo     that you can put it back when done.
  echo.
  goto END
:CANNOT_SHELL
  echo   No.
  if not "%TRIEDONCE%"=="" if "%TOOLSCOPIED%"=="" (call :COPY_TOOLS & goto DO_FIND)
  if "%msg%"=="error: device offline" (
    echo.
    echo *** Your computer has not been authorized to debug your device.
    echo.
    echo * Please UNLOCK YOUR DEVICE if necessary, and then check your device
    echo   for an authorization dialog.
    echo.
    echo * If you do NOT see an authorization dialog, don't worry...
    echo   This is a very common problem.
    echo   Please enter Settings, Developer options and turn USB debugging
    echo   off and on again. Then, try again.
    echo   Additionally, you might try tapping to Revoke USB authorization,
    echo   but only if toggling USB debugging does not do the trick.
    echo   ^(Try this process again, first.^)
    echo.
    echo * If/when you DO see an authorization dialog, check the box to Always
    echo   allow this computer to debug, if you are on a trusted computer.
    echo   Tap OK on your device to continue.
  ) else (
    echo * Please enter Developer options and try turning USB debugging off
    echo   and on again.
    echo   Additionally, you might try tapping to Revoke USB authorization,
    echo   but only if toggling USB debugging does not do the trick.
    echo   ^(Try this process again, first.^)
    echo.
    echo * If you have more than one Android device or emulator connected,
    echo   it is easiest to just close the unnecessary ones at the moment,
    echo   but you could open a terminal before running this script, and
    echo   run 'export ANDROID_SERIAL=DEVICE', replacing DEVICE with the
    echo   serial of the device you want to use, found in the output of
    echo   the 'adb devices' command, and listed here:
    adb devices
  )
  goto END
:NO_BUSYBOX
  echo * Busybox binary not found.
  echo * You may download the required 'busybox-armv4tl' binary from the
  echo   http://www.busybox.net website, specifically from the following page:
  echo   http://www.busybox.net/downloads/binaries/latest
  echo * Place the 'busybox-armv4tl' binary in the files/ folder. It will auto-
  echo   matically be renamed to 'busybox'.
  echo.
:GO_BUSYBOX
  set /P response=Download busybox with curl? ^(Y/N^) 
  if "%response%"=="N" goto GO_BUSYBOX_URL
  if "%response%"=="n" goto GO_BUSYBOX_URL
  if not "%response%"=="Y" if not "%response%"=="y" (echo Please enter Y or N. & goto GO_BUSYBOX)
:DOWNLOAD_WITH_CURL
  curl http://www.busybox.net/downloads/binaries/latest/busybox-armv4tl -o files/busybox && goto TOP || echo Download with curl failed.
:GO_BUSYBOX_URL
  set /P response=Visit busybox URL for download? ^([Y]/N^) 
  if "%response%"=="N" goto BUSYBOX_TRY_AGAIN
  if "%response%"=="n" goto BUSYBOX_TRY_AGAIN
  if not "%response%"=="Y" if not "%response%"=="y" if not "%response%"=="" (echo Please enter Y or N. & goto GO_BUSYBOX_URL)
  start http://www.busybox.net/downloads/binaries/latest
:BUSYBOX_TRY_AGAIN
  echo * If you did not save busybox directly into the files/ folder, move
  echo   or copy it there now.
  echo * Once busybox-armv4tl is in the files/ folder, you may continue.
  echo.
  set /P response=Is busybox in the files/ folder now? ^([Y]/N^) 
  if "%response%"=="N" goto ABORT
  if "%response%"=="n" goto ABORT
  if not "%response%"=="Y" if not "%response%"=="y" if not "%response%"=="" (echo Please enter Y or N. & goto BUSYBOX_TRY_AGAIN)
  goto TOP
:COPY_TOOLS
  set TOOLSCOPIED=2
  echo * There's another thing we can try.
  pause
  echo.
  echo * This probably will not help, but we can try copying the tools to the
  echo   main folder.
  echo.
  echo * If you've placed custom files in the main folder that have the
  echo   same names as files in the tools\ folder, yours will be replaced.
  echo.
  set /P response=Is it OK to copy files from tools\ to the main folder anyway? ^(Y/[N]^) 
  if not "%response%"=="y" if not "%response%"=="Y" goto :EOF
  adb kill-server >NUL 2>NUL
  tskill adb 2>NUL
  set TOOLSCOPIED=1
  echo.
  echo * OK. Copying...
  copy /Y tools\* . >NUL 2>NUL || goto COPY_FAIL
  echo.
  echo * Checking again. Let's see if it works now...
  goto :EOF
:REMOVE_COPIED_TOOLS
  echo.
  echo Removing tools copied to main folder...
  echo.
  adb kill-server >NUL 2>NUL
  pushd tools
  for %%F in (*) do del /Q ..\%%F >NUL 2>NUL
  echo Done.
  popd
  goto :EOF
:COPY_FAIL
  echo.
  echo *** Couldn't even copy the tools to the main folder.
  echo.
  echo * Is the tools folder present?
  echo * Do you have write permission to this folder?
  echo.
  echo *** PROCESS ABORTED.
  goto :END
:END
  if "%TRYAGAIN%"=="1" goto TRYAGAIN
  if "%TOOLSCOPIED%"=="1" call :REMOVE_COPIED_TOOLS
  popd
  adb kill-server >NUL 2>NUL
  pause
  echo Bye!
  endlocal
  goto :EOF
:TRYAGAIN
  set TRIEDONCE=1
  set /P response=Would you like to try again? ^([Y]/N^) 
  if not "%response%"=="y" if not "%response%"=="Y" if not "%response%"=="" goto ABORT
  echo.
  echo Trying again...
  echo.
  goto TOP
:END2
  if "%TOOLSCOPIED%"=="1" call :REMOVE_COPIED_TOOLS
  popd
  echo Bye!
  endlocal
  goto :EOF
:ABORT
  set TRYAGAIN=0
  adb kill-server >NUL 2>NUL
  echo.
  echo * Sorry. Please try running the process again to review
  echo   troubleshooting steps, or visit the XDA thread for GhettoRoot.
  echo.
  echo *** PROCESS ABORTED.
  goto END
:SUCCESS
  echo.
  echo *** Everything finished. I hope it worked for you!
  echo     Try opening SuperSU to check if root works.
  echo     If SuperSU isn't even there then, well, I guess it didn't work...
  echo.
  set TRYAGAIN=0
  goto END
