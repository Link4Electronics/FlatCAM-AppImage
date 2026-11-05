#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=./flatcam.png
export DEPLOY_OPENGL=1
export DEPLOY_PYTHON=1

# Deploy dependencies
quick-sharun                    \
	./AppDir/bin/flatcam        \
	/usr/lib/python*/lib-dynload/_tkinter* \
	/usr/lib/libtcl*.so*        \
	/usr/lib/libtk*.so*         \
	/usr/lib/tcl*               \
	/usr/lib/tk*

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --test ./dist/*.AppImage
