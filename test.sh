set -ex
pushd ~/code/github/freeflowuniverse/crystallib
#bash doc.sh

#v -enable-globals -stats test crystallib/baobab
v -enable-globals -stats test crystallib/builder
#v -enable-globals -stats test crystallib/clients
#v -enable-globals -stats test crystallib/core
#v -enable-globals -stats test crystallib/crypt
#v -enable-globals -stats test crystallib/data
#v -enable-globals -stats test crystallib/installers
#v -enable-globals -stats test crystallib/osal
#v -enable-globals -stats test crystallib/servers
#v -enable-globals -stats test crystallib/threefold
#v -enable-globals -stats test crystallib/tools
#v -enable-globals -stats test crystallib/ui
#v -enable-globals -stats test crystallib/web

# OK TO IGNORE FOR NOW
# v -stats test tmux
# v -stats test knowledgetree
# v -stats test crpgp

popd


echo "TESTS OK"