GhettoRoot v0.3.2 Testing

Please see the LICENSE.txt file for details on copying and usage (GPLv3).

Version Note:
-------------------------------------------------------------------------------
WARNING:  ESPECIALLY with this version, PLEASE make sure you have backups of
          your important applications and their data!
          Alternatively, you might be safer changing config.txt to the
          old value as listed below.
This version is called 'Testing' because I haven't really had time to test it
fully, and there's a bunch of new stuff, namely the de* (*-removal) scripts.

I DON'T KNOW HOW WELL THE DE* CODE WORKS. You may want to give me some time
to see how my device holds up before testing yourself, or check out
files/root.sh to see what the new stuff does, but I do need other people to
test as well, so I've changed the config.txt to include the new features,
sans --debloat.

If you DO NOT want to try the new features, change config.txt to the following:
./root.sh --root --disable-knox --disable-ota

However, even the --disable-knox and --disable-ota code has changed.
Your mileage may vary!

Search files/root.sh for ### DEBLOAT, ### DEKNOX, ### DEOTA, ## DESURVEILLANCE,
etc. to see exactly what they do.
-------------------------------------------------------------------------------

This software will attempt to root your device and might void its warranty.
Please BACK UP ANYTHING IMPORTANT before continuing.

Note: By default, this package attempts to disable Knox and OTA update packages.
      If you'd rather this not happen, scroll to CONFIGURATION.

1) Install USB drivers for your device if needed, for Windows.
   Koush's drivers are a good bet. 'Download Windows Installer', and run:
   https://github.com/koush/UniversalAdbDriver
2) Download the busybox-arm4vl binary. The installer will help you with this.
   You can get it manually from http://www.busybox.net, specifically from
   http://www.busybox.net/downloads/binaries/latest
   Place the binary in the files/ folder. It will be automatically renamed
   to 'busybox'.
3) Enable USB debugging. If necessary, go to 'About device' under Settings and tap
   the Build number several times to enable the Developer options. Go back, and
   go to Developer options, and enable USB debugging there.
4) Plug in your device to your computer.
5) Unlock your device's lockscreen if it is locked.
6) Manually choose a USB mode from the notification, or wait for the Installer mode
   phase of USB to end, which takes about 30 seconds. If your device does not have
   an Installer mode, skip this. If you're not sure, just wait the 30 seconds.
7) If/when a popup appears asking for authorization for your PC, allow it.
8) If a popup does not appear and has never appeared before, or you clicked Cancel,
   or you're just having a lot of trouble, go to Developer option and toggle USB 
   debugging off and on again. Then, try again. You may need to disconnect and re-
   connect your device or tap Revoke USB authorization if nothing seems to help.
9) On Linux or OS X, enter a terminal at the folder you extracted the zip file to,
   and type chmod +x INSTALL.sh.
10)To run, execute INSTALL.cmd on Windows.
   On Linux or OS X, type the following in the same terminal: ./INSTALL.sh
11)Follow the on-screen instructions.

CONFIGURATION:
  Open up config.txt, and customize as follows, adding or removing arguments
    as you see fit. It should always start with ./root.sh
  *** ENSURE THE CONTENTS OF config.txt IS A *SINGLE LINE*.
  *** COMMENTS WITHIN config.txt ARE NOT PERMITTED.
  Default: ./root.sh --root --deknox --deota --desurveillance
  Former default: ./root.sh --root --disable-knox --disable-ota

Usage: ./root.sh [OPTION] [COMMAND]
  With no arguments, --root is implied.

  Main options
  --root, --supersu    Install SuperSU (permaroot)
  --deknox             Remove Knox (recommended)
  --deota              Remove OTA packages (recommended)
  --debloat            Remove Bloat (recommended)
  --desurveillance     Remove some surveillance (recommended)
  --disable-ota        Disable OTA update-related packages
  --disable-knox       Disable Knox packages
  --really-remove      Actually remove things instead of
                       putting them in $jaildir
  --undo               Try to undo the specified option.
                       If you had used --really-remove then
                       it won't work for deknox, debloat, deota.

  Anti-convenience options
  --no-mount-rw        Don't mount / and /system read-write
  --no-sepermissive    Don't set SEAndroid to permissive
  --no-chmod-scripts   Don't chmod 0755 all scripts in
                       $TMPDIR

  COMMAND: Command to be run after other options.
           Arguments may follow.
           If unspecified, will look for and run custom.sh.

  ex. ./root.sh --root
      ./root.sh --root --undo
      ./root.sh --root --deknox --deota --debloat
      ./root.sh cp /sdcard/build.prop /system/build.prop

MODSTRINGS:
  To use a custom device modstring, edit/create modstring.txt as follows.
  This is for advanced users who are having trouble rooting and happen
    to know a modstring that will work or want to painstakingly guess at it.
  *** ENSURE THE CONTENTS OF modstring.txt IS A *SINGLE LINE*.
  *** COMMENTS WITHIN modstring.txt ARE NOT PERMITTED.
  For more info, see: https://towelroot.com/modstrings.html
  Format is slightly different: no temp_root and no 1337.
  Default (if not otherwise detected): 0 1 0 4

  Modstring format: METHOD ALIGN LIMIT_OFFSET HIT_IOV
    Formatting key: [Default value]PARAMETER NAME: value range: description
    [0]METHOD: 0-sendmmsg, 1-recvmmsg, 2-sendmsg, 3-recvmsg:
       This typically does not need to be changed.
    [1]ALIGN: 0/1: attack all 8 IOVs hit with MAGIC
       This behavior may/may not match up with original ALIGN behavior.
       Currently, enabling this causes HIT_IOV to go unused.
    [0]LIMIT_OFFSET: 0-8192: offset of addr_limit in thread_info, multiple of 4
       If desperate, download manufacturer's kernel sources to check headers.
       Rarely necessary, but 7380 is needed for newer Samsung device models.
    [4]HIT_IOV: 0-7: offset to rt_waiter in vulnerable futex_wait_requeue_pi.
       see vulnerable futex_wait_requeue_pi function for your kernel if needed.

INCLUDED SOFTWARE:
  ghettoroot:
    Description:
      Rooting tool. Implements exploit CVE-2014-3153.
      Targets Verizon Galaxy Note II (SCH-I605) 4.4.2, firmware ND7.
    Project/Source URL, courtesy of XDA Developers:
      http://forum.xda-developers.com/note-2-verizon/general/root-adb-ghettoroot-v0-1-towelroot-port-t2864125
    Related projects/code:
      Towelroot by geohot:
        http://forum.xda-developers.com/showthread.php?t=2783157
      Unlicensed, unattributed code from fi01's GitHub:
        https://gist.github.com/fi01/a838dea63323c7c003cd
      getroot.c from timwr's Github:
        https://github.com/timwr/CVE-2014-3153/blob/master/getroot.c
    License: GNU Public License v3 (GPLv3)
    LICENSE stored as LICENSE.txt in this directory.

  SuperSU v2.02:
    SuperSU is the Superuser access management tool of the future ;-)
    Author: chainfire
    Project URL: http://forum.xda-developers.com/showthread.php?t=1538053
    Date retrieved: 2014-08-31

  Android Debug Bridge (ADB) 1.0.31:
    ADB is part of the Android Open Source Project (AOSP).
    Project/Source URL: http://source.android.com/
    Binaries provided by Mozilla:
      https://ftp.mozilla.org/pub/mozilla.org/labs/android-tools/
    License: Apache License 2.0
    LICENSE replicated in each adb directory under tools/
    Date retrieved: 2014-09-06
    Date modified on server: 2013-11-08

  busybox - not yet bundled, but downloaded
    BusyBox: The Swiss Army Knife of Embedded Linux
    Project URL: http://www.busybox.net
    Source URL: http://www.busybox.net/source.html
    Source tarballs: http://www.busybox.net/downloads/
    Binaries: http://www.busybox.net/downloads/binaries/
      busybox-arm4vl
    License: Mozilla Public License (MPL) 1.1
    LICENSE stored as LICENSE_BUSYBOX.txt in this directory

  wintee:
    Win32 equivalent of the 'tee' command in coreutils
    Project URL: https://code.google.com/p/wintee/
    Source bundled: src/wintee
    LICENSE file in src/wintee
    Date retrieved: 2014-09-03
    Date modified on server: 2008-08-21

  curl 7.37.1.0:
    curl is a command line tool for transferring data with URL syntax
    Project URL: http://curl.haxx.se/
    Source/Download URL: http://curl.haxx.se/download.html
    License: MIT/X derivate (Free Software)
    LICENSE stored as LICENSE_CURL.txt in this directory
    Retrieval URL: http://www.paehl.com/open_source/?CURL_7.37.1
      WITH SSL.
    Date retrieved: 2014-09-07

CREDITS:
  fi01 for his exploit code on github:
    https://gist.github.com/fi01/a838dea63323c7c003cd
  tinyhack.com for the helpful post on the Futex bug:
    http://tinyhack.com/2014/07/07/exploiting-the-futex-bug-and-uncovering-towelroot/
  GEOHOT for developing towelroot in the first place!! :-)
    http://forum.xda-developers.com/showthread.php?t=2783157
  chainfire, for SuperSU - THANK YOU for the lenient distribution policy
  NetworkingPro at xda-developers for the assistance to all. :-)
  Other folks at xda-developers for testing and offering support
  Google, of course, and the Android Open Source Project
