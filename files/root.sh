#!/system/bin/sh
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
[ -z "$TMPDIR" ] && export TMPDIR=/data/local/tmp/ghetto
failures=
successes=
jaildir=/system/.jail
will_undo=0

### ROOT MAIN
do_root() {
  if [ $will_undo -eq 0 ]; then
    mkdir /tmp 2>/dev/null
    mkdir -p "$TMPDIR" 2>/dev/null
    if [ ! -f "$TMPDIR/busybox" ] || [ ! -f "$TMPDIR"/*SuperSU*.zip ]; then
      if [ -d /sdcard/ghettoroot ]; then
        cp -a /sdcard/ghettoroot/* "$TMPDIR/"
      elif [ -d /storage/extSdCard/ghettoroot ]; then
        cp -a /storage/extSdCard/ghettoroot/* "$TMPDIR/";
      elif [ -d /storage/sdcard1/ghettoroot ]; then
        cp -a /storage/sdcard1/ghettoroot/* "$TMPDIR/"
      fi
    fi
    if ! "$TMPDIR/busybox" unzip -o "$TMPDIR"/*SuperSU*.zip META-INF/com/google/android/update* -d "$TMPDIR/"; then
      echo "Could not find/unzip SuperSU" >&2
      echo "Please place an UPDATE-SuperSU-*.zip file in the main folder before running the install script" >&2
      return 1
    fi
    echo
    echo "About to run SuperSU install script"
    # Execute the SuperSU updater script (update-binary), but strip out the references to YouTube and Maps first.
    grep -E -v 'YouTube\.apk|Maps\.apk' "$TMPDIR/META-INF/com/google/android/update-binary" > "$TMPDIR/META-INF/com/google/android/update-binary-2"
    if ! sh "$TMPDIR/META-INF/com/google/android/update-binary-2" "" 1 "$TMPDIR"/*SuperSU*.zip; then
      echo "Installing SuperSU failed" >&2
      return 1
    fi
    return 0
  else
    # some voodoo here... run all the supersu install commands until the first copy,
    # which ends up accomplishing the removal of SuperSU, as of 2.02
    sed '/^cp /q' "$TMPDIR/META-INF/com/google/android/update-binary" | head -n -1 > "$TMPDIR/META-INF/com/google/android/update-binary-2"
    sh "$TMPDIR/META-INF/com/google/android/update-binary-2"
    # just in case it didn't actually get removed, here are the known removal
    # commands as of 2.02
    rm -f /system/bin/su
    rm -f /system/xbin/su
    rm -f /system/xbin/daemonsu
    rm -f /system/xbin/sugote
    rm -f /system/xbin/sugote-mksh
    rm -f /system/bin/.ext/.su
    rm -f /system/bin/install-recovery.sh
    rm -f /system/etc/install-recovery.sh
    rm -f /system/etc/init.d/99SuperSUDaemon
    rm -f /system/etc/.installed_su_daemon
    rm -f /system/app/Superuser.apk
    rm -f /system/app/Superuser.odex
    rm -f /system/app/SuperUser.apk
    rm -f /system/app/SuperUser.odex
    rm -f /system/app/superuser.apk
    rm -f /system/app/superuser.odex
    rm -f /system/app/Supersu.apk
    rm -f /system/app/Supersu.odex
    rm -f /system/app/SuperSU.apk
    rm -f /system/app/SuperSU.odex
    rm -f /system/app/supersu.apk
    rm -f /system/app/supersu.odex
    rm -f /data/dalvik-cache/*com.noshufou.android.su*
    rm -f /data/dalvik-cache/*com.koushikdutta.superuser*
    rm -f /data/dalvik-cache/*com.mgyun.shua.su*
    rm -f /data/dalvik-cache/*Superuser.apk*
    rm -f /data/dalvik-cache/*SuperUser.apk*
    rm -f /data/dalvik-cache/*superuser.apk*
    rm -f /data/dalvik-cache/*eu.chainfire.supersu*
    rm -f /data/dalvik-cache/*Supersu.apk*
    rm -f /data/dalvik-cache/*SuperSU.apk*
    rm -f /data/dalvik-cache/*supersu.apk*
    rm -f /data/dalvik-cache/*.oat
    rm -f /data/app/com.noshufou.android.su-*
    rm -f /data/app/com.koushikdutta.superuser-*
    rm -f /data/app/com.mgyun.shua.su-*
    rm -f /data/app/eu.chainfire.supersu-*
  fi
}

really_remove=0
jail() {
  rel=$(dirname "$1")
  jrd=${rel##/system}
  jrd=$jaildir/${jrd##/}
  jr=$jrd/$(basename "$1")
  if [ $will_undo -eq 0 ]; then
    if [ -f "$1" ]; then
      if [ "$really_remove" == "0" ]; then
        [ ! -d "$jrd" ] && mkdir -p "$jrd" 2>/dev/null || true
        mvout=$(mv "$1" "$jr" 2>&1 | grep -v 'No such')
        [ -z "$mvout" ] || {
          echo "$mvout" >&2
          false
        }
      else
        rm -f "$1"
      fi
    fi
  else
    rel=$rel/$(basename "$1")
    mv "$jr" "$1"
    [ -f "$rel" ] && return 0 || return 1
  fi
}

jaild() {
  if [ $will_undo -eq 0 ]; then
    if [ "$really_remove" == "0" ]; then
      if [ -d "$1" ]; then
        #rel=${1##/system}
        find "$1" -type f -print | while read f; do jail "$f"; done
        rmdir "$1" 2>/dev/null || true
      fi
    else
      rm -rf "$1"
    fi
  else
    rel=$1
    rel=${rel##/system}
    jr="$jaildir/$rel"
    if [ -d "$jr" ]; then
      find "$jr" -type f -print | while read f; do
        dst=${f##$jaildir}
        dst=/system/${dst##/}
        [ ! -d "$dst" ] && mkdir "$dst"
        mv "$f" "$dst/"
      done
    else
      return 1
    fi
  fi
}

disable_package_if_found() {
  name=$1
  package=$2
  if pm list packages $package 2>&1 | grep $package >/dev/null; then
    if [ $will_undo -eq 0 ]; then
      pm disable $package >/dev/null 2>&1 && echo "Disabled $name ($package)" || { echo "Could not disable $name ($package)"; return 1; }
    else
      pm enable $package >/dev/null 2>&1 && echo "Enabled $name ($package)" || { echo "Could not enable $name ($package)"; return 1; }
    fi
    return 0
  else
    echo "Could not find $name ($package)"
    return 0
  fi
}

add_result() {
  value=$1
  fail=$2
  if [ -n "$value" ]; then
    if [ $fail -eq 0 ]; then
      [ -n "$successes" ] && successes="$successes, $value" || successes=$value
    else
      [ -n "$failures" ] && failures="$failures, $value" || failures=$value
    fi
  fi
}

### HELP
show_usage() {
  cat <<EOF
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
EOF
}

modstring=
gotarguments=0
will_root=0
will_chmod=1
will_mountrw=1
will_sepermissive=1
will_disableknox=0
will_disableota=0
will_deknox=0
will_deota=0
will_debloat=0
will_desurveil=0
alias find="\"$TMPDIR\"/busybox find"

GETOPT=$(./busybox getopt -o h --long help,root,supersu,deknox,deota,debloat,really-remove,undo,disable-knox,disable-ota,no-mountrw,no-sepermissive,desurveillance \
       -n 'root.sh' -- "$@")
if [ $? != 0 ]; then exit 1; fi
eval set -- "$GETOPT"
while true; do
  fail=1
  value=
  case $1 in
    -h|--help)
      show_usage
      exit 0
      ;;
    --root|--supersu)
      will_root=1
      shift;;
    --disable-knox)
      will_disableknox=1
      shift;;
    --deknox)
      will_deknox=1
      shift;;
    --disable-ota)
      will_disableota=1
      shift;;
    --deota)
      will_deota=1
      shift;;
    --debloat)
      will_debloat=1
      shift;;
    --really-remove)
      really_remove=1
      shift;;
    --no-mount-rw)
      will_mountrw=0
      shift;;
    --no-sepermissive)
      will_sepermissive=0
      shift;;
    --desurveillance)
      will_desurveil=1
      shift;;
    --no-chmod-scripts)
      will_chmod=0
      shift;;
    --undo)
      will_undo=1
      shift;;
    --)
      shift
      break;;
    *)
      show_usage
      echo Invalid argument.
      exit 1
      ;;
  esac
  gotarguments=1
done

### MOUNT-RW
if [ $will_mountrw -eq 1 ] || [ $will_disableknox -eq 1 ]; then
  echo Remounting filesystems
  fail=0
  mount -o remount,rw /system || fail=1
  mount -o remount,rw / || fail=1
  [ $fail -eq 1 ] && add_result "remount-rw" 1
fi

### SEPERMISSIVE
if [ $will_sepermissive -eq 1 ]; then
  echo Setting SE Permissive
  setenforce 0 >/dev/null || add_result "sepermissive" 1
fi

[ $will_chmod -eq 1 ] && chmod 0755 *.sh

[ $# -eq 0 ] && [ $gotarguments -eq 0 ] && will_root=1

### ROOT
if [ $will_root -eq 1 ]; then
  fail=1
  if [ $will_undo -eq 0 ]; then
    value="Install SuperSU"
    echo Installing SuperSU...
  else
    value="Remove SuperSU"
    echo Removing SuperSU...
  fi
  do_root && fail=0
  add_result "$value" "$fail"
fi

### DEKNOX
if [ $will_deknox -eq 1 ]; then
  f=0
  if [ $will_undo -eq 0 ]; then
    value="Deknox"
    echo Removing Knox...
  else
    value="Reknox"
    echo Trying to bail Knox out from jail...
  fi
  for x in \
    app/KNOXAgent app/KnoxAttestationAgent app/KNOXStore app/KnoxMigrationAgent \
    app/KnoxSetupWizardClient app/ContainerAgent app/ContainerEventsRelayManager app/KNOXStub \
    app/Bridge app/EdmSimPinService app/EdmSysScopeService app/EdmVpnServices \
    app/KnoxSetupWizardStub app/MDMApp app/RCPComponents app/SysScope \
    app/UniversalMDMClient priv-app/SPDClient framework/ContainerProxies \
    framework/com.policydm.features; do
    # Brutal begins at app/Bridge
    # http://forum.xda-developers.com/galaxy-s4-active/general/knoxout-complete-brutal-knox-destruction-t2807064/page2
    for y in odex jar apk; do
      let t+=1; jail $x.$y || let f+=1
    done
  done
  for x in container containers preloadedkiosk preloadedsso \
    etc/secure_storage/com.sec.knox.seandroid \
    etc/secure_storage/com.sec.knox.store; do
    let t+=1; jaild /system/$x || let f+=1
  done
  # Brutal
  for x in  \
    bin/containersetup \
    bin/tima_dump_log \
    etc/permissions/sec_mdm.xml \
    etc/permissions/com.policydm.feature.xml \
    etc/permissions/mycontainerbadge.png \
    lib/libcordon.so \
    lib/libmealy.so \
    lib/libspdkeygen.so \
    lib/libtwifingr.so \
    lib/libtyrfingr.so \
    lib/libknoxdrawglfunction.so \
    tima_measurement_info; do
    let t+=1; jail /system/$x || let f+=1
  done
  mkdir /data/local/tmp 2>/dev/null >/dev/null
  KNOXLINES='^ *(ro\.build\.knox|ro\.config\.dha_empty_max_knox|ro\.config\.knox|ro\.config\.tima|ro\.security\.mdpp\.ux|security\.mdpp|ro\.security\.mdpp\.ver|ro\.security\.mdpp\.release|security\.mdpp\.result)'
  if [ $will_undo -eq 0 ]; then
    if [ ! -f /system/.build.prop.deknox-backup ]; then
      cp -a /system/build.prop /system/.build.prop.deknox-backup
    fi
    cp -a /system/build.prop /data/local/tmp/deknoxbuild.prop
    grep -E -v "$KNOXLINES" /data/local/tmp/deknoxbuild.prop > /system/build.prop
    cat >> /system/build.prop <<EOF
ro.config.knox=0
ro.build.knox.container=
ro.config.tima=0
ro.config.knox=0
EOF
    rm -f /data/local/tmp/deknoxbuild.prop
  else
    let t+=1
    if [ ! -f /system/.build.prop.deknox-backup ]; then
      let f+=1
      add_result "$value" "$f"
      return 1
    else
      grep -E "$KNOXLINES"
    fi
    cp -a /system/build.prop /data/local/tmp/reknoxbuild.prop
    grep -E -v "$KNOXLINES" /data/local/tmp/reknoxbuild.prop > /system/build.prop
    grep -E "$KNOXLINES" /system/.build.prop.deknox-backup >> /system/build.prop
    rm -f /data/local/tmp/reknoxbuild.prop
  fi
  add_result "$value" "$f"
fi

if [ $will_disableknox -eq 1 ] && ([ $will_deknox -eq 0 ] || [ $will_undo -eq 1 ]); then
  fail=1
  if [ $will_undo -eq 0 ]; then
    value="Disable Knox"
    echo Disabling Knox...
  else
    value="Enable Knox"
    echo Enabling Knox...
  fi
  disable_package_if_found "Knox" "com.sec.knox.seandroid" && fail=0
  add_result "$value" "$fail"
fi

### DEOTA
if [ $will_deota -eq 1 ]; then
  f=0; t=0
  if [ $will_undo -eq 0 ]; then
    value="De-OTA"
    echo Removing OTA stuff...
  else
    value="Re-OTA"
    echo Trying to restore OTA stuff from jail...
  fi
  for x in policydm LocalFota LocalFOTA FotaClient SDM; do
    for y in odex apk; do
      jail /system/app/$x.$y || let f+=1
      let t+=1
    done
  done
  for y in odex apk; do jail /system/app/FWUpgrade.$y; done

  #jail /system/app/SyncmlDM.$x || fail=1
  #jail /system/app/wssyncmlnps.$x || fail=1
  #jail /system/app/wssyncmldm.$x || fail=1

  [ $will_undo -eq 1 ] && [ $f -ne $t ] && f=0
  add_result "$value" $f
fi

if [ $will_disableota -eq 1 ] && ([ $will_deota -eq 0 ] || [ $will_undo -eq 1 ]); then
  fail=0
  if [ $will_undo -eq 0 ]; then
    $value="Disabling OTA stuff"
  else
    $value="Enabling OTA stuff"
  fi
  echo $value...
  disable_package_if_found "Security Policy Updater" "com.policydm" || fail=1
  disable_package_if_found "LocalFota OTA Updates" "com.LocalFota" || fail=1
  disable_package_if_found "FWUpgrade" "com.sec.android.fwupgrade" || fail=1
  disable_package_if_found "Samsung Data Migration Tool" "com.samsung.sdm" || fail=1
  #disable_package_if_found "Device Management" "com.wssyncmldm" || fail=1
  #disable_package_if_found "wssyncmlnps" "com.wssnps" || fail=1
  add_result "$value" "$fail"
fi

### DEBLOAT
if [ $will_debloat -eq 1 ]; then
  f=0; t=0
  if [ $will_undo -eq 0 ]; then
    value="Debloat"
  else
    value="Rebloat"
  fi
  echo $value...
  for x in app/Aetherpal app/Amazon_Audible app/Amazon_IMDB app/Amazon_MP3 \
    app/Amazon_Shopping app/Amazon_Widget app/Books app/com.gotv.nflgamecenter.us.lite \
    app/Drive app/FWUpgrade app/GuidedTour app/HelpHub \
    app/Kindle app/Magazines app/Music2 app/PlayGames \
    app/SilentLog app/SSuggest_J_DeviceOnly app/TcpdumpService \
    app/Videos app/VisualVoiceMail app/VZNavigator app/VzTones \
    priv-app/Amazon_Appstore priv-app/Kies priv-app/KLMSAgent priv-app/SamsungVideoLITE \
    app/AllshareFileShare app/Allshare app/AllshareControlShare  \
    app/SamsungHub priv-app/SamsungLink18 priv-app/SPPPushClient_Prod \
    app/MobilePrintSvc_Samsung priv-app/wssyncmlnps app/YahoostockWidget app/ShareShotService \
    priv-app/sCloudQuotaApp priv-app/sCloudDataRelay priv-app/sCloudDataSync \
    priv-app/sCloudSyncSNote priv-app/sCloudSyncBrowser priv-app/sCloudSyncCalendar \
    priv-app/Samsungservice priv-app/GroupPlay_25 app/SyncmlDM app/SyncmlDS \
    priv-app/Samsungservice_H; do
    for y in odex apk; do
      jail /system/$x.$y || let f+=1
      let t+=1
    done
  done
  [ $will_undo -eq 1 ] && [ "$f" -ne "$t" ] && f=0
  add_result "$value" $f
fi

#### DESURVEILLANCE
f=0; t=0
if [ $will_desurveil -eq 1 ]; then
  if [ $will_undo -eq 0 ]; then
    value="Remove some surveillance"
    echo $value...
    for x in /system/priv-app/intelligenceservice*; do
      jail "$x" || let f+=1
      let t+=1
    done
    [ $f -ne $t ] && f=0
  else
    value="Keep/restore some surveillance"
    echo $value...
    for x in $jaildir/priv-app/intelligenceservice*; do
      jail "$x" || let f+=1
      let t+=1
    done
  fi
  let t+=1; jaild /system/etc/secure_storage/com.samsung.android.intelligenceservice || let f+=1
  add_result "$value" $f
fi

if [ $# -gt 0 ]; then
  if [ -n "$1" ]; then
    echo Executing custom command...
    value="command"
    "$@" && fail=0 || fail=1
  fi
elif [ -f custom.sh ]; then
  value="custom.sh"
  echo Executing custom.sh...
  ./custom.sh && fail=0 || fail=1
  add_result "$value" $fail
elif [ -f CUSTOM.sh ]; then
  value="CUSTOM.sh"
  echo Executing CUSTOM.sh...
  ./CUSTOM.sh && fail=0 || fail=1
  add_result "$value" $fail
fi

# remove empty directories in jail
find "$jaildir" -type d -depth -exec rmdir "{}" \; 2>/dev/null || true

[ -n "$successes" ] || [ -n "$failures" ] && echo "Completion summary:"
[ -n "$successes" ] && echo "  Successful tasks: $successes" 
[ -n "$failures" ] && echo "  Failed tasks: $failures"
exit 0
