
all:
	ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk
	mv -f libs/armeabi/ghettoroot ../files/
	rmdir libs/armeabi
	rmdir libs

clean:
	rm -rf libs
	rm -rf obj
