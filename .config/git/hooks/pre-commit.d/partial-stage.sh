#!/usr/bin/bash

mapfile -t partial < <(LC_ALL=C comm -12 <(git-staged | sort) <(git-unstaged | sort))

if [ ! ${#partial[@]} -eq 0  ]
then
    echo "Partially staged files:"
    echo "${partial[*]}"
    exit 1
fi
