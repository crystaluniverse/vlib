#!/usr/bin/env bash
set -ex

SOURCE=${BASH_SOURCE[0]}
DIR_OF_THIS_SCRIPT="$( dirname "$SOURCE" )"
cd $DIR_OF_THIS_SCRIPT
CRYSTAL_HOME="$( realpath $DIR_OF_THIS_SCRIPT )"

cd ${CRYSTAL_HOME}/..
mkdir -p vdocs/v
mkdir -p vdocs/crystal
rm -rf vdocs/v/
v doc  -m  -no-color -f md -o vdocs/v/

cd crystallib
v doc  -m  -no-color -f md -o vdocs/crystal/