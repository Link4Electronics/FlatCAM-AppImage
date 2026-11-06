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
    gdal               \
    glpk               \
    hicolor-icon-theme \
    npm                \
    pybind11           \
    python-absl        \
    python-attrs       \
    python-cligj       \
    python-cycler      \
    python-dateutil    \
    python-dill        \
    python-fonttools   \
    python-freetype-py \
    python-hatch-vcs   \
    python-kiwisolver  \
    python-lxml        \
    python-matplotlib  \
    python-opengl      \
    python-pyserial    \
    python-pyqt5       \
    python-qrcode      \
    python-reportlab   \
    python-rtree       \
    python-scipy       \
    python-shapely     \
    python-simplejson  \
    python-svglib      \
    qt5-svg            \
    re2                \
    scip               \
    swig               \
    tk


echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

PRE_BUILD_CMDS="sed -i '/^check() {/,/^}/d' ./PKGBUILD" make-aur-package python-ezdxf
make-aur-package python-mypy-protobuf
PRE_BUILD_CMDS='sed -i "s#^  cp pybind11_protobuf.patch \${_base}-\${pkgver}/patches#&\n  sed -i \"s|f02a2b7653bc50eb5119d125842a3870db95d251|8e1cd4edfca6922c6d968eba297190145bc21f02|\" \"\${_base}-\${pkgver}/cmake/dependencies/CMakeLists.txt\"\n  sed -i \"s|ortools/base/source_location.h|absl/types/source_location.h|\" \${_base}-\${pkgver}/ortools/math_opt/cpp/message_callback.{h,cc} \${_base}-\${pkgver}/ortools/math_opt/solvers/gurobi/g_gurobi.{h,cc}\n  sed -i \"s|PyInt_AsLong|PyLong_AsLong|g\" \${_base}-\${pkgver}/ortools/base/python-swig.h\n  sed -i \"/^ *py::keep_alive<1, 0>(),\$/d;s|py::keep_alive<1, 0>(), ||;s|py::return_value_policy::reference,|py::return_value_policy::reference_internal,|g\" \${_base}-\${pkgver}/ortools/sat/python/cp_model_helper.cc\n  sed -i \"s|py::return_value_policy::reference, py::keep_alive<0, 1>()|py::return_value_policy::reference_internal|g\" \${_base}-\${pkgver}/ortools/sat/python/wrappers.cc\n  sed -i \"s|PyInt_Check|PyLong_Check|g;s|PyInt_AsLong|PyLong_AsLong|g\" \${_base}-\${pkgver}/ortools/util/python/vector.swig \${_base}-\${pkgver}/ortools/constraint_solver/python/routing_types.swig\n  sed -i -e \"/^namespace detail {/a template <typename AttrType>\" -e \"/^namespace detail {/a struct type_caster_enum_type_enabled<AttrType, std::enable_if_t<(GetIndexIfAttr<AttrType>() >= 0)>> : std::false_type {};\" \${_base}-\${pkgver}/ortools/math_opt/elemental/python/elemental.cc#" ./PKGBUILD
sed -i "s#-DUSE_SYSTEM_PYBIND=ON#-DUSE_SYSTEM_PYBIND=ON -DBUILD_TESTING=OFF -DPYBIND11_PROTOBUF_BUILD_TESTING=OFF#" ./PKGBUILD' make-aur-package python-or-tools
make-aur-package python-affine
CC=gcc CXX=g++ make-aur-package python-rasterio
make-aur-package python-svg.path
make-aur-package python-hatch-cython
make-aur-package python-vispy

echo "Building FlatCAM..."
echo "---------------------------------------------------------------"
REPO="https://bitbucket.org/jpcgt/flatcam"
BRANCH="Beta"
VERSION="$(git ls-remote "$REPO" "refs/heads/$BRANCH" | cut -c 1-9 | head -1)"
git clone --depth 1 -b "$BRANCH" "$REPO" ./flatcam
echo "$VERSION" > ~/version

# numpy 2 dropped the np.Inf alias
find ./flatcam -name '*.py' -exec sed -i \
    -e 's/\bnp\.Inf\b/np.inf/g' \
    -e 's/^from numpy import Inf$/from numpy import inf as Inf/' {} +

# vispy >= 0.10 replaced _marker_dict with symbol_shaders, which already
# provides the '++' marker that this patch was adding
sed -i '/markers\._marker_dict/d' ./flatcam/appGUI/VisPyPatches.py

python3 - <<'PY'
import pathlib


def patch(path, old, new):
    p = pathlib.Path(path)
    text = p.read_text()
    if old not in text:
        raise SystemExit('patch target missing in %s: %r' % (path, old))
    p.write_text(text.replace(old, new))


# Finder.find_module() and Loader.load_module() were removed in Python 3.12
patch('flatcam/tclCommands/__init__.py',
      '    module = loader.find_module(name).load_module(name)\n', '')

patch('flatcam/appPreProcessor.py',
      'from importlib.machinery import SourceFileLoader',
      'from importlib.util import module_from_spec, spec_from_file_location')
patch('flatcam/appPreProcessor.py',
      "                SourceFileLoader('FlatCAMPostProcessor', file).load_module()",
      "                spec = spec_from_file_location('FlatCAMPostProcessor', file)\n"
      "                spec.loader.exec_module(module_from_spec(spec))")

# the bundled preprocessors sit next to this file, not in the working directory
patch('flatcam/appPreProcessor.py',
      "        os.path.join('preprocessors', '*.py')\n",
      "        os.path.join(os.path.dirname(os.path.realpath(__file__)), 'preprocessors', '*.py'),\n"
      "        os.path.join('preprocessors', '*.py')\n")
PY

mkdir -p ./AppDir/bin
cd ./flatcam
python -O -m py_compile ./*.py
rm -rf ./doc ./tests
cp -r ./* ../AppDir/bin

cat > ../AppDir/bin/flatcam <<'EOF'
#!/bin/sh
exec python3 "$(dirname "$(readlink -f "$0")")/FlatCAM.py" "$@"
EOF
chmod +x ../AppDir/bin/flatcam

cp ./assets/resources/flatcam_icon256.png ../flatcam.png
