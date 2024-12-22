#!/usr/bin/env bash
set -ex

SOURCE=${BASH_SOURCE[0]}
DIR_OF_THIS_SCRIPT="$( dirname "$SOURCE" )"
cd $DIR_OF_THIS_SCRIPT
CRYSTAL_HOME="$( realpath $DIR_OF_THIS_SCRIPT )"

cd ${CRYSTAL_HOME}

v fmt -w examples
v fmt -w crystallib

rm -rf docs

cd ${CRYSTAL_HOME}/crystallib


rm -rf _docs
rm -rf docs


v doc -m -f html . -readme -comments -no-timestamp

mv _docs ../docs

rm -rf vdocs
mkdir -p vdocs/v
mkdir -p vdocs/crystal

#v doc -m crystallib -f md . -comments -no-timestamp -no-color -o vdocs/crystal/

v doc -m  -no-color -f md -o vdocs/v/

#cd crystallib
v doc  -m  -no-color -f md -o vdocs/crystal/

if ! [[ ${OSTYPE} == "linux-gnu"* ]]; then
    cd ..
    open docs/index.html
fi

echo "DOC DONE"