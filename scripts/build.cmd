rem * GhettoRoot is licensed under GPLv3 or later. See file LICENSE.txt in root of package tree.
ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk
move libs/armeabi/ghettoroot .
rmdir libs/armeabi
rmdir libs
