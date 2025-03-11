#!/usr/bin/env bash

set -e

feed=$(curl -q https://www.nuget.org/packages/ChilliCream.Nitro.App/atom.xml)

stable_regex="ChilliCream\.Nitro\.App\/(\d+\.\d+\.\d+)"
insider_regex="ChilliCream\.Nitro\.App\/(\d+\.\d+\.\d+-insider.\d+)"

stable_version=$(echo "$feed" | grep -v insider | grep -oP "$stable_regex" | head -n 1 | cut -d'/' -f2)
insider_version=$(echo "$feed" | grep insider | grep -oP "$insider_regex" | head -n 1 | cut -d'/' -f2)

echo "Stable version: $stable_version"
echo "Insider version: $insider_version"

function upgrade() {
    local version=$1

    if [ ! -f "Nitro-$version-linux-x86_64.AppImage" ]; then
        wget https://cdn.chillicream.com/app/Nitro-$version-linux-x86_64.AppImage
        b2sum=$(b2sum Nitro-$version-linux-x86_64.AppImage | awk '{print $1}')

        sed -i "0,/pkgver=.*/{s/pkgver=.*/pkgver=$(echo $version | tr '-' '_')/}" PKGBUILD
        sed -i "s/b2sums=.*/b2sums=(\"$b2sum\"/" PKGBUILD

        makepkg -si --noconfirm
        makepkg --printsrcinfo > .SRCINFO

        git add PKGBUILD .SRCINFO
        git commit -m "$version"
        git push
    fi
}

pushd ~/repos/aur/nitro-bin
upgrade $stable_version
popd

pushd ~/repos/aur/nitro-beta-bin
upgrade $insider_version
popd
