#!/bin/bash

staged=$(git-staged)

if [[ " ${staged[@]} " =~ " PKGBUILD " ]]
then
    makepkg --printsrcinfo > .SRCINFO
    git add .SRCINFO
fi
