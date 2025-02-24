CROSSOVER_VERSION="23.5.0"
CROSSOVER_DLFILE="crossover-sources-$CROSSOVER_VERSION.tar.gz"
CROSSOVER_DLLINK="https://media.codeweavers.com/pub/crossover/source/$CROSSOVER_DLFILE"
WORKSPACE=$(pwd)
export PATH="$(brew --prefix bison)/bin:$(brew --prefix cx-llvm)/bin:$(brew --prefix flex)/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if [[ ! -f ${CROSSOVER_DLFILE} ]]; then
    wget $CROSSOVER_DLLINK
fi

if [[ ! -d "${WORKSPACE}/sources" ]]; then
    tar xf ${CROSSOVER_DLFILE}
fi

brew_install () {
    brew update
    brew install \
            bison              \
            gcenx/wine/cx-llvm \
            flex               \
            gettext            \
            mingw-w64          \
            pkgconfig
    brew install \
            freetype           \
            molten-vk          \
            sdl2

}

patch_all () {
    pushd sources/wine
    patch -p1 < ${WORKSPACE}/distversion.patch
    popd
    pushd sources
    patch -p1 < ${WORKSPACE}/header-patch.patch
    popd
}

config_wine_base () {
    mkdir -p ${BUILD_DIR}/
    pushd ${BUILD_DIR}
    ${WORKSPACE}/sources/wine/configure \
                    --disable-option-checking \
                    --disable-tests \
                    --without-alsa \
                    --without-capi \
                    --without-dbus \
                    --without-gettext \
                    --without-gettextpo \
                    --without-gsm \
                    --without-inotify \
                    --without-krb5 \
                    --without-netapi \
                    --without-openal \
                    --without-oss \
                    --without-pulse \
                    --without-quicktime \
                    --without-sane \
                    --without-udev \
                    --without-usb \
                    --without-v4l2 \
                    --without-x \
                    $@
    popd
}

make_wine_base () {
    pushd ${BUILD_DIR}
    make -j$(sysctl -n hw.activecpu 2>/dev/null)
    popd
}

prepare_env_base () {
    export CC=clang
    export CXX=clang++
    export CFLAGS=
    export CXXFLAGS=
    export CPPFLAGS=
    export LDFLAGS=
    export PKG_CONFIG_PATH=
    export LIBRARY_PATH=
    export LD_LIBRARY_PATH=
    export C_INCLUDE_PATH=
    export CROSSCFLAGS="-g -O2"
    export CROSSCXXFLAGS=
    export CROSSCPPFLAGS=
    export CROSSLDFLAGS=
    export ac_cv_lib_soname_MoltenVK="libMoltenVK.dylib"
    export ac_cv_lib_soname_vulkan=""
}

prepare_env_wine64 () {
    prepare_env_base
    mkdir -p $WORKSPACE/build/wine64
    export BUILD_DIR=$WORKSPACE/build/wine64
}

config_wine64 () {
    prepare_env_wine64
    config_wine_base --enable-win64 --with-vulkan
}

make_wine64 () {
    prepare_env_wine64
    make_wine_base
}

prepare_env_wine32on64 () {
    prepare_env_base
    mkdir -p $WORKSPACE/build/wine32on64
    export BUILD_DIR=$WORKSPACE/build/wine32on64
    export CFLAGS="-std=c17"
    export CPPFLAGS=
    export CROSSCFLAGS=
    export CROSSCPPFLAGS=
}

config_wine32on64 () {
    prepare_env_wine32on64
    config_wine_base \
        --enable-win32on64 \
        --with-wine64=$WORKSPACE/build/wine64 \
        --without-cms \
        --without-openal \
        --without-gstreamer \
        --without-gphoto \
        --without-krb5 \
        --without-sane \
        --without-vulkan \
        --disable-vulkan_1 \
        --disable-winedbg \
        --disable-winevulkan \
        --without-freetype
}

make_wine32on64 () {
    prepare_env_wine32on64
    make_wine_base
}

prepare_env_freetype () {
    prepare_env_base
    export CFLAGS="-m32"
    mkdir -p $WORKSPACE/build/freetype
    export BUILD_DIR=$WORKSPACE/build/freetype
}

submodule_freetype () {
    pushd $WORKSPACE/sources/freetype
    pushd subprojects
    git clone https://github.com/nyorain/dlg
    popd
    popd
}

config_freetype () {
    prepare_env_freetype
    pushd ${BUILD_DIR}
    cmake -S ${WORKSPACE}/sources/freetype -B .
    popd
}

make_freetype () {
    prepare_env_freetype
    pushd ${BUILD_DIR}
    make -j
    popd
}