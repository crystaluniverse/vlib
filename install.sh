#!/usr/bin/env bash
set -e

SOURCE=${BASH_SOURCE[0]}
DIR_OF_THIS_SCRIPT="$( dirname "$SOURCE" )"
cd $DIR_OF_THIS_SCRIPT
ABS_DIR_OF_SCRIPT="$( realpath $DIR_OF_THIS_SCRIPT )"

mkdir -p ~/.vmodules/freeflowuniverse

rm -f ~/.vmodules/freeflowuniverse/crystallib
ln -s $ABS_DIR_OF_SCRIPT/crystallib ~/.vmodules/freeflowuniverse/crystallib

rm -f ~/.vmodules/freeflowuniverse/webcomponents
ln -s ~/code/github/freeflowuniverse/webcomponents/webcomponents ~/.vmodules/freeflowuniverse/webcomponents




if [[ "${OSTYPE}" == "darwin"* ]]; then
    cp ~/code/github/freeflowuniverse/crystallib/scripts/node/vrun ~/hero/bin
    cp ~/code/github/freeflowuniverse/crystallib/scripts/node/vtest ~/hero/bin
    chmod 770 ~/hero/bin/vrun
    chmod 770 ~/hero/bin/vtest
else
    cp ~/code/github/freeflowuniverse/crystallib/scripts/node/vrun /usr/local/bin/
    cp ~/code/github/freeflowuniverse/crystallib/scripts/node/vtest /usr/local/bin/
    chmod 770  /usr/local/bin/vrun
    chmod 770  /usr/local/bin/vtest
fi

#TODO: needs to become part of hero
# v ${ABS_DIR_OF_SCRIPT}/cli/crystallib.v
# rm -f /usr/local/cli/crystallib
# sudo cp ${ABS_DIR_OF_SCRIPT}/cli/crystallib /usr/local/bin/crystallib
# rm -f ${ABS_DIR_OF_SCRIPT}/cli/crystallib

bash ~/code/github/freeflowuniverse/crystallib/crystallib/develop/juggler/copy_templates.sh

echo "INSTALL OK"


