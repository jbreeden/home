#!/usr/bin/env bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
repo="$PWD"

function log () {
    echo "$@"
    "$@"
}

git ls-files | grep -v install.sh | {
    while read f; do
        dir="$(dirname "$f")"
        if [[ "$dir" != . ]]; then
            log mkdir -p "$HOME/$dir"
        fi
        if [ "$repo/$f" -ef "$HOME/$f" ]; then
            rm "$HOME/$f"
        fi
        log ln -sf --backup -T "$repo/$f" "$HOME/$f"
    done
}

echo "✅ HOME config files are linked to this repo."
