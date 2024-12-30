#!/usr/bin/env bash
set -e

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$MYDIR"

echo "Enter the commit message:"
read commit_message

git add . -A ; git commit -m "$commit_message"; git pull ; git push
