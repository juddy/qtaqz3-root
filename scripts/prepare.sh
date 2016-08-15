#!/bin/sh
# * GhettoRoot is licensed under GPLv3 or later. See file LICENSE.txt in root of package tree.
cd "$(dirname "$0")"
adb shell mkdir -p /data/local/tmp/ghetto/
adb push ../files /data/local/tmp/ghetto/ || { echo "*** Could not push files."; exit 1; }
adb shell 'cd /data/local/tmp/ghetto; chmod 0755 ghettoroot busybox *.sh'
echo
echo "*** Necessary files pushed and chmod'd."
echo "    Give it a brief moment or your device will be overwhelmed."
