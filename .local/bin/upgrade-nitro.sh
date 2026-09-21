#!/usr/bin/env bash
# Bump the nitro-bin / nitro-beta-bin AUR packages to the newest versions that
# actually have a Linux AppImage on ChilliCream's CDN.
#
# Version source: the NuGet atom feed for ChilliCream.Nitro.App (the CDN's own
# latest-linux.yml / insider-linux.yml are stale, still BananaCakePop 18.x).
# NuGet versions can appear days before (or without) a Linux build, so every
# candidate is probed on the CDN first and skipped if it 404s.

set -euo pipefail

cdn="https://cdn.chillicream.com/app"

feed=$(curl -fsSL https://www.nuget.org/packages/ChilliCream.Nitro.App/atom.xml)

# Anchor on the closing tag so 33.0.0 is not extracted from 33.0.0-insider.5.
stable_regex='ChilliCream\.Nitro\.App/\K\d+\.\d+\.\d+(?=<)'
insider_regex='ChilliCream\.Nitro\.App/\K\d+\.\d+\.\d+-insider\.\d+(?=<)'

# Feed is newest-first; take the first match of each kind.
stable_version=$(grep -oP "$stable_regex" <<<"$feed" | head -n 1)
insider_version=$(grep -oP "$insider_regex" <<<"$feed" | head -n 1)

echo "Stable version:  $stable_version"
echo "Insider version: $insider_version"

appimage_name() { echo "Nitro-$1-linux-x86_64.AppImage"; }

# HEAD requests 404 on this CDN even for existing files, so probe with a 1-byte GET.
cdn_has() {
    curl -fsL -r 0-0 -o /dev/null "$cdn/$(appimage_name "$1")" 2>/dev/null
}

# upgrade <repo dir> <version>
upgrade() {
    local dir=$1 version=$2
    local pkgver=${version//-/_}   # PKGBUILD pkgver may not contain '-'
    local file
    file=$(appimage_name "$version")

    echo "==> $(basename "$dir"): $version"

    if [ -z "$version" ]; then
        echo "    no version found in feed, skipping"
        return
    fi

    local current
    current=$(sed -n 's/^pkgver=//p' "$dir/PKGBUILD" | head -n 1)
    if [ "$current" = "$pkgver" ]; then
        echo "    already at $pkgver, skipping"
        return
    fi

    if ! cdn_has "$version"; then
        echo "    $file not on CDN yet (no Linux build published), skipping"
        return
    fi

    pushd "$dir" >/dev/null

    [ -f "$file" ] || wget -q --show-progress "$cdn/$file"
    local b2
    b2=$(b2sum "$file" | awk '{print $1}')

    sed -i -e "0,/^pkgver=/s/^pkgver=.*/pkgver=$pkgver/" \
           -e "s/^pkgrel=.*/pkgrel=1/" \
           -e "0,/^b2sums=/s/^b2sums=.*/b2sums=(\"$b2\"/" PKGBUILD

    makepkg -si --noconfirm
    makepkg --printsrcinfo > .SRCINFO

    git add PKGBUILD .SRCINFO
    git commit -m "$version"
    git push

    popd >/dev/null
}

upgrade ~/repos/aur/nitro-bin "$stable_version"
upgrade ~/repos/aur/nitro-beta-bin "$insider_version"
