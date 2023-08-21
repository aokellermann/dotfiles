#!/bin/bash

staged=$(git-staged)

for file in $staged
do
    if [[ $file == *.rs ]]
    then
        cargo fmt -- "$file"
        git add "$file"
    fi
done
