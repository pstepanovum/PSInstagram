#!/usr/bin/env bash

set -e

CMAKE_OSX_ARCHITECTURES="arm64e;arm64"
CMAKE_OSX_SYSROOT="iphoneos"

# Prerequisites
if [ -z "$(ls -A modules/FLEXing)" ]; then
    echo -e '\033[1m\033[0;31mFLEXing submodule not found.\nPlease run the following command to checkout submodules:\n\n\033[0m    git submodule update --init --recursive'
    exit 1
fi

# Building modes
if [ "$1" == "sideload" ];
then

    MAKEARGS='SIDELOAD=1'
    FLEXPATH='.theos/obj/debug/FLEXing.dylib .theos/obj/debug/libflex.dylib'
    COMPRESSION=9

    # Clean build artifacts
    make clean
    rm -rf .theos

    # Check for decrypted instagram ipa
    ipaFile="$(find ./packages/*com.burbn.instagram*.ipa -type f -exec basename {} \;)"
    if [ -z "${ipaFile}" ]; then
        echo -e '\033[1m\033[0;31m./packages/com.burbn.instagram.ipa not found.\nPlease put a decrypted Instagram IPA in its path.\033[0m'
        exit 1
    fi

    echo -e '\033[1m\033[32mBuilding PSInstagram tweak for sideloading (as IPA)\033[0m'

    make $MAKEARGS

    PSINSTAGRAMPATH=".theos/obj/debug/PSInstagram.dylib"

    # Create IPA File
    echo -e '\033[1m\033[32mCreating the IPA file...\033[0m'
    rm -f packages/PSInstagram-sideloaded.ipa
    cyan -i "packages/${ipaFile}" -o packages/PSInstagram-sideloaded.ipa -f $PSINSTAGRAMPATH $FLEXPATH -c $COMPRESSION -m 15.0 -du

    # No ipapatch: PSInstagram's own sideload fixes replace it (its helper crashes on Instagram 449)

    echo -e "\033[1m\033[32mDone, we hope you enjoy PSInstagram!\033[0m\n\nYou can find the ipa file at: $(pwd)/packages\nTo sign and install it with your own certificate, use ./dev.sh"

elif [ "$1" == "rootless" ];
then
    
    # Clean build artifacts
    make clean
    rm -rf .theos

    echo -e '\033[1m\033[32mBuilding PSInstagram tweak for rootless\033[0m'

    export THEOS_PACKAGE_SCHEME=rootless
    make package

    echo -e "\033[1m\033[32mDone, we hope you enjoy PSInstagram!\033[0m\n\nYou can find the deb file at: $(pwd)/packages"

elif [ "$1" == "rootful" ];
then

    # Clean build artifacts
    make clean
    rm -rf .theos

    echo -e '\033[1m\033[32mBuilding PSInstagram tweak for rootful\033[0m'

    unset THEOS_PACKAGE_SCHEME
    make package

    echo -e "\033[1m\033[32mDone, we hope you enjoy PSInstagram!\033[0m\n\nYou can find the deb file at: $(pwd)/packages"

else
    echo '+--------------------+'
    echo '|PSInstagram Build Script|'
    echo '+--------------------+'
    echo
    echo 'Usage: ./build.sh <sideload/rootless/rootful>'
    exit 1
fi