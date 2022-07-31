#!/bin/bash

set -e;

GIT_DIR="$1"

git --git-dir "$GIT_DIR" fetch -qPp
GONE_BRANCHES="$(git --git-dir "$GIT_DIR" branch -vv | awk '/^[^*].*: gone]/{print $1}')"
[ -n "$GONE_BRANCHES" ] && echo "$GIT_DIR" && echo "$GONE_BRANCHES" | xargs git --git-dir "$GIT_DIR" branch -d
