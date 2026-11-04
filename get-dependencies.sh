#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    coin-or-cbc        \
    coin-or-clp        \
    cython             \
    eigen              \
    glpk               \
    hicolor-icon-theme \
    pybind11           \
    python-absl        \
    python-cycler      \
    python-dateutil    \
    python-dill        \
    python-fonttools   \
    python-freetype-py \
    python-kiwisolver  \
    python-lxml        \
    python-matplotlib  \
    python-opengl      \
    python-pyqt5       \
    python-qrcode      \
    python-reportlab   \
    python-rtree       \
    python-scipy       \
    python-shapely     \
    python-simplejson  \
    python-svglib      \
    re2                \
    scip               \
    swig               \
    tk


echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

PRE_BUILD_CMDS="sed -i '/^check() {/,/^}/d' ./PKGBUILD" make-aur-package python-ezdxf
make-aur-package python-mypy-protobuf
make-aur-package python-or-tools
make-aur-package python-rasterio
make-aur-package python-svg.path
make-aur-package python-vispy

echo "Building FlatCAM..."
echo "---------------------------------------------------------------"
REPO="https://bitbucket.org/jpcgt/flatcam"
VERSION="$(git ls-remote "$REPO" HEAD | cut -c 1-9 | head -1)"
git clone --depth 1 "$REPO" ./flatcam
echo "$VERSION" > ~/version

mkdir -p ./AppDir/bin
cd ./flatcam && python -O -m py_compile *.py
rm -rf ./*.sh ./doc ./tests
cp -r * ../AppDir/bin
