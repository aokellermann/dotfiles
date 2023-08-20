#!/usr/bin/bash

staged=$(git-staged)

if [[ ${staged[@]} =~ PKGBUILD ]]
then
    res=$(namcap PKGBUILD)
    if [ -n "$res" ]
    then
        echo "$res"
        exit 1
    fi
fi
