#!/bin/sh
# * GhettoRoot is licensed under GPLv3 or later. See file LICENSE.txt in root of package tree.
cd "$(dirname "$0")"/..
modstring=
config=
[ -f modstring.txt ] && modstring=$(cat modstring.txt)
[ -n "$modstring" ] && modstring="-m \"$modstring\" "
echo
if [ $# -ne 0 ]; then
  adb shell "cd /data/local/tmp/ghetto; ./ghettoroot ${modstring}$@"
else
  [ -f config.txt ] && config=$(cat config.txt)
  adb shell "cd /data/local/tmp/ghetto; ./ghettoroot ${modstring}$config"
fi
