# Hacked version of ghettoroot

Tested on Linux - macOS, BSD, Windows may work just as well.

This is really just a means to capture what I suspect were the pivotal steps to get root on my tablet. I tried a bunch of other things, including compiling the 'american sign language' exploit for 3.10, but I ran into header issues with my cross build toolchain.

I have changed permissions and ownership on a number of files (diff from the [ghettoroot-v0.3.2.zip distribution here:])http://forum.xda-developers.com/attachment.php?attachmentid=2930321&d=1410249799)).


## Prerequisites

- Install adb

Debian:

    apt install android-tools-adb

- Sideload SuperSU

    adb install SuperSU.apk

## ghettoize

Connect your formerly useless Verizon tablet via USB, enable developer mode and debugging (do the tap dance).

From this project directory, run INSTALL.sh then:

    adb shell

The sideloaded su binary should provide root access. It may be necessary to install KingRoot to satisfy some of the bits ghettoroot doesn't handle.

    su

If this works, you're in good shape. Go ahead and remount the root filesystem RW:

    remount -o remount,rw /

# Bugs

Yes. Many - the output from the INSTALL.sh script will report loads of failures.


