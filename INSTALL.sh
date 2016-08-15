#!/bin/bash
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# *  This file is part of GhettoRoot.                                       *
# *                                                                         *
# *  GhettoRoot is free software: you can redistribute it and/or modify     *
# *  it under the terms of the GNU General Public License as published by   *
# *  the Free Software Foundation, either version 3 of the License, or      *
# *  (at your option) any later version.                                    *
# *                                                                         *
# *  GhettoRoot is distributed in the hope that it will be useful,          *
# *  but WITHOUT ANY WARRANTY; without even the implied warranty of         *
# *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
# *  GNU General Public License for more details.                           *
# *                                                                         *
# *  You should have received a copy of the GNU General Public License      *
# *  along with GhettoRoot.  If not, see <http://www.gnu.org/licenses/>.    *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
TRYAGAIN=1
BASEDIR=$(dirname "$0")
OS=$(uname -s)
OLDPATH=$PATH

cd "$BASEDIR"
case "$OS" in
  "Darwin") NEWPATH=$BASEDIR/tools/osx/adb;;
  "Linux") NEWPATH=$BASEDIR/tools/linux$(getconf LONG_BIT)/adb;;
  "CYGWIN"*) NEWPATH=$BASEDIR/tools/win/adb;;
  "MSYS"*) NEWPATH=$BASEDIR/tools/win/adb;;
  "MINGW"*) NEWPATH=$BASEDIR/tools/win/adb;;
  *)
    echo "Unknown OS: '$OS'"
    exit 1
    ;;
esac

export NEWPATH=$NEWPATH
export PATH=$BASEDIR/scripts:$OLDPATH:$NEWPATH

pause() {
  sleep 0.1
  read -n 1 -r -p "Press any key to continue . . . ";
  echo;
}

getyesno() {
  shopt -s nocasematch
  if [[ $1 == y || $1 == "yes" ]]; then
    echo 0
  elif [[ $1 == n || $1 == "no" ]]; then
    echo 1
  else
    echo $2
  fi
}
ask() {
  prompt=$1
  if [ -n "$2" ]; then emptyvalue=$(getyesno $2 $2); prompt="$prompt [$2] ";
  else emptyvalue=-1; fi
  if [ -n "$3" ]; then othervalue=$(getyesno $3 $3);
  else othervalue=-1; fi
  yn=
  sleep 0.1
  read -p "$prompt" yn
  if [ -z "$yn" ]; then
    yn=$emptyvalue
  else
    yn=$(getyesno $yn $othervalue)
  fi
  if [ $yn -eq -1 ]; then
    echo "Please enter (y)es or (n)o."
    ask "$@"
    return $?
  fi
  return $yn
}

echo ---- GhettoRoot Installer ----
main() {
  chmod +x tools/*/adb/adb tools/*/* scripts/* *.sh >/dev/null 2>&1 || {
    echo "* Could not set permissions on executables.  Are you the owner of the"
    echo "    extracted files?"
    echo "* Worst case, you may need to run this as root (prefix with sudo or run"
    echo "  su first)."
    echo
  }
  if [ ! -f files/busybox ]; then
    if [ ! -f files/busybox-armv4tl ]; then
      if [ -f busybox ]; then
        mv busybox files/busybox
      elif [ -f busybox-armv4tl ]; then
        mv busybox-armv4tl files/busybox
      else
        echo "*** BUSYBOX BINARY NOT FOUND."
        echo "* You may download the required 'busybox-armv4tl' binary from the"
        echo "  http://www.busybox.net website, specifically from the following page:"
        echo "  http://www.busybox.net/downloads/binaries/latest"
        echo "* Place the 'busybox-armv4tl' binary in the files/ folder. It will auto-"
        echo "  matically be renamed to 'busybox'."
        echo
        if ask "Download busybox with curl? (Y/N) "; then
          if ! curl http://www.busybox.net/downloads/binaries/latest/busybox-armv4tl -o files/busybox; then
            echo "* Download failed. Try manually."
          else
            echo "* Download completed."
            main "$@"
            return
          fi
        fi
        if ask "Try again?" y; then
          main "$@"
          return
        fi
      fi
    else
      mv files/busybox-armv4tl files/busybox
    fi
  fi
  if [ ! -f files/*SuperSU*.zip ]; then
    if [ ! -f *SuperSU*.zip ]; then
      echo "*** SUPERSU PACKAGE NOT FOUND."
      echo "* You may download the required UPDATE-SuperSU package from the"
      echo "  XDA Developers SuperSU post:"
      echo "    http://forum.xda-developers.com/showthread.php?t=1538053"
      echo "  specifically, from the following page:"
      echo "    http://download.chainfire.eu/452/SuperSU"
      echo "* Place the UPDATE-SuperSU zip file in the files/ folder."
      echo "* Please note that this file name is CASE-SENSITIVE."
    else
      mv *SuperSU*.zip files/
    fi
    abort
  fi
  echo "  Can we start up ADB?";
  if adb start-server; then
    echo "  Yes!"
    echo
  else
    echo "  No."
    echo
    echo "* Please install the Android SDK and try again."
    echo "* If you have already installed the SDK, check your PATH variable"
    echo "  in Start, Run, sysdm.cpl, Advanced, Environment Variables and make"
    echo "  sure that the SDK's platform-tools subdirectory is in, at least,"
    echo "  your user PATH environment variable. Create a new PATH variable"
    echo "  if necessary. Check the Android SDK installation instructions"
    echo "  for more information."
    echo
    end "$@"
  fi
  echo "  Can a device be found?"
  if [ $(adb devices | grep -v "List of devices attached" | wc -l) -gt 1 ]; then
    echo "  Yes!"
    echo
  else
    echo "  No. Cannot see your Android device."
    echo
    echo "*** USB CONNECTION CHECKLIST: (1/2)"
    echo
    echo "* Have you unlocked your device on the lockscreen?"
    echo
    echo "* Have you tried switching USB modes via the USB notification?"
    echo "  Try toggling between Camera and MTP mode."
    echo  
    echo "* Is your device actually plugged in?"
    echo
    echo "* Have you downloaded and installed the proper drivers?"
    echo "  - Try searching for and using: Koush Universal ADB driver"
    echo
    echo "* Have you enabled USB debugging?  Sometimes it gets disabled!"
    echo "  - You can enable this by going to Settings, About device on your"
    echo "    device and tapping Build number several times. Then, go Back,"
    echo "    enter Developer options, and check to enable USB debugging."
    echo
    pause
    echo
    echo "*** USB CONNECTION CHECKLIST: (2/2)"
    echo
    echo "* Is nothing working so far?"
    echo "  - One other thing to try is to access a hidden menu on your device"
    echo "    to change USB settings. Sometimes this helps. See below."
    echo
    echo "  - On the Verizon Galaxy Note 2 with 4.4.2 firmware, you can enter"
    echo "    ##366633# and then try switching back and forth between Enable"
    echo "    and Disable DM Mode, reconnecting your device and/or toggling"
    echo "    USB debugging in between. This is a last-ditch effort, but it"
    echo "    might help."
    echo
    echo "  - Remember that USSD code and the original Enable/Disable value so"
    echo "    that you can put it back when done."
    echo
    pause
    end "$@"
  fi
  echo "  Can we communicate with a device?"
  msg=$(adb shell echo "  Yes! (This message came from your device.)" 2>&1)
  if [ ! $? -eq 0 ]; then
    echo "  No."
    if [ "$msg" = "error: device offline" ]; then
      echo
      echo "*** Your computer has not been authorized to debug your device."
      echo
      echo "* Please UNLOCK YOUR DEVICE if necessary, and then check your device"
      echo "  for an authorization dialog."
      echo
      echo "* If you do NOT see an authorization dialog, don't worry..."
      echo "  This is a very common problem."
      echo "  Please enter Settings, Developer options and turn USB debugging"
      echo "  off and on again. Then, try again."
      echo "  Additionally, you might try tapping to Revoke USB authorization,"
      echo "  but only if toggling USB debugging does not do the trick."
      echo "  (Try this process again, first.)"
      echo
      echo "* If/when you DO see an authorization dialog, check the box to Always"
      echo "  allow this computer to debug, if you are on a trusted computer."
      echo "  Tap OK on your device to continue."
    else
      echo "* Please enter Developer options and try turning USB debugging off"
      echo "  and on again."
      echo "  Additionally, you might try tapping to Revoke USB authorization,"
      echo "  but only if toggling USB debugging does not do the trick."
      echo "  (Try this process again, first.)"
      echo
      echo "* If you have more than one Android device or emulator connected,"
      echo "  it is easiest to just close the unnecessary ones at the moment,"
      echo "  but you could open a terminal before running this script, and"
      echo "  run 'export ANDROID_SERIAL=DEVICE', replacing DEVICE with the"
      echo "  serial of the device you want to use, found in the output of"
      echo "  the 'adb devices' command, and listed here:"
      adb devices
    fi
    echo
    end "$@"
  else
    echo "$msg"
  fi
  echo
  echo "* READ the README file before continuing."
  echo "*** Please wait until your device is out of Installer mode before continuing."
  echo "    You can tell by looking at the USB mode in your Notifications."
  echo "    Your device automatically switches out of Installer in about 30 seconds."
  echo "    If you aren't sure, just wait 30 seconds and then press Y."
  echo
  if ! ask "Is your device OUT of INSTALLER mode?" n; then
    echo
    echo "*** Well, please wait as instructed, and then relaunch the process."
    echo "    I don't want to damage your device."
    echo "*** You may say Y to this next time if your device does not have"
    echo "    an Installer mode."
    echo "    If you aren't sure, just wait 30 seconds next time and then press Y."
    abort
  fi
  echo
  echo "* WARNING: This process may void your warranty or cause unexpected damage"
  echo "* to your device. By using this software, you are accepting these risks."
  echo
  echo "* This is your last chance to back out!"
  echo "* Please ensure your device does not have any busy apps running!"
  echo
  if ! ask "Continue? (Y/N) "; then abort; fi
  if sh "$BASEDIR/scripts/clean.sh" 2>&1; then
    echo
    echo "* Cleaned!"
  else
    echo
    echo "* Not cleaned, but no biggie."
  fi
  echo
  if sh "$BASEDIR/scripts/prepare.sh" 2>&1; then
    echo
    echo "* Preparation files transferred!"
  else
    echo
    echo "*** Could not send preparation files!"
    end "$@"
  fi
  echo
  if ! sh "$BASEDIR/scripts/ghettoroot.sh" "$@" 2>&1; then
    echo
    echo "*** Script returned an error... Did it fail?"
  fi
  TRYAGAIN=0
  echo
  echo "*** ghettoroot execution completed! Investigate the results..."
  echo
  echo "* All that's left is a bit of cleanup, or press N to end this."
  if ! ask "Clean up?" y; then success "$@"; fi
  echo
  echo "* When your device has restarted (if applicable), press any key to clean"
  echo "  out the temporary files on your device that were used for the rooting"
  echo "  process and are located at /data/local/tmp/ghetto."
  echo
  pause
  echo "UNLOCK your device when it is started up again, before continuing."
  echo
  pause
  clean
  success "$@"
}

clean() {
  if sh "$BASEDIR/scripts/clean.sh" 2>&1; then
    echo "* Cleaned!"
  else
    echo
    echo "* Could not clean temporary files, but that's not so bad."
    echo
    if ask "Try cleaning again?" n; then clean; fi
  fi
}

abort() {
  TRYAGAIN=0
  echo
  echo "* Sorry. Please try running the process again to review"
  echo "  troubleshooting steps, or visit the XDA thread for GhettoRoot."
  echo
  echo "*** PROCESS ABORTED."
  end
}

end() {
  if [ $TRYAGAIN -eq 1 ]; then
    if ask "Would you like to try again?" y; then
      export PATH=$BASEDIR/scripts:$NEWPATH:$OLDPATH
      echo
      main "$@"
      exit
    else
      abort
    fi
  fi
  adb kill-server >/dev/null 2>&1
  pause
  echo "Bye!"
  exit
}

success() {
  echo
  echo "*** Everything finished. I hope it worked for you!"
  echo "    Try opening SuperSU to check if root works."
  echo "    If SuperSU isn't even there then, well, I guess it didn't work..."
  echo
  TRYAGAIN=0
  end "$@"
}

rm -f debug.txt
main "$@" | tee debug.txt
exit $?
