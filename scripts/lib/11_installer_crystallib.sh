
function crystal_deps_install {
    set -e

    if [[ "${OSNAME}" == "ubuntu" || "${OSNAME}" == "arch"* ]]; then        
        cd /tmp
        # package_install autoconf libtool libsqlite3-dev gcc
        # wget https://github.com/bitcoin-core/secp256k1/archive/refs/tags/v0.4.1.tar.gz
        # tar -xvf v0.4.1.tar.gz
        # cd secp256k1-0.4.1/
        # ./autogen.sh
        # ./configure
        # make -j 5
        # make install   
        # apt-get remove -y gcc
        package_install tcc
    # elif [[ "${OSNAME}" == "darwin"* ]]; then
    #     brew install secp256k1        
    # # elif [[ "${OSNAME}" == "arch"* ]]; then
    # #     pacman -Su extra/libsecp256k1
    # else
    #     echo "can't find instructions to install secp256k1"
    #     exit 1
    fi


      #       set -x
      #       cd /tmp
      #       wget https://github.com/bitcoin-core/secp256k1/archive/refs/tags/v0.3.2.tar.gz
      #       tar -xvf v0.3.2.tar.gz
      #       cd secp256k1-0.3.2/
      #       ./autogen.sh
      #       ./configure
      #       sudo make -j 5
      #       sudo make install   

}

function crystal_lib_pull {

    if [[ -z "${DEBUG}" ]]; then
        return 0
    fi

    pushd $DIR_CODE/github/freeflowuniverse/crystallib 2>&1 >> /dev/null     
    if [[ $(git status -s) ]]; then
        echo "There are uncommitted changes in the Git repository crystallib."
        return 1
    fi
    git pull
    popd 2>&1 >> /dev/null
}

function crystal_lib_get {
    
    execute_with_marker "crystal_deps_install" crystal_deps_install
    execute_with_marker "v_install" v_install

    rm -rf ~/.vmodules/freeflowuniverse/
    rm -rf ~/.vmodules/threefoldtech/
    mkdir -p ~/.vmodules/freeflowuniverse/
    mkdir -p ~/.vmodules/threefoldtech/   

    mkdir -p $DIR_CODE/github/freeflowuniverse
    if [[ -d "$DIR_CODE/github/freeflowuniverse/crystallib" ]]
    then
        pushd $DIR_CODE/github/freeflowuniverse/crystallib 2>&1 >> /dev/null     
        if [[ -z "$sshkeys" ]]; then
            echo
        else
            git remote set-url origin git@github.com:freeflowuniverse/crystallib.git
        fi               
        set +e
        git checkout $CLBRANCH
        set -e
        popd 2>&1 >> /dev/null
    else
        pushd $DIR_CODE/github/freeflowuniverse 2>&1 >> /dev/null
        if [[ -z "$sshkeys" ]]; then
            git clone --depth 1 --no-single-branch https://github.com/freeflowuniverse/crystallib.git
        else
            git clone --depth 1 --no-single-branch git@github.com:freeflowuniverse/crystallib.git
        fi        
        crystal_lib_pull
        cd crystallib
        set +e
        git checkout $CLBRANCH
        set -e
        popd 2>&1 >> /dev/null
    fi

    mkdir -p ~/.vmodules/freeflowuniverse
    rm -f ~/.vmodules/freeflowuniverse/crystallib
    ln -s "$DIR_CODE/github/freeflowuniverse/crystallib/crystallib" ~/.vmodules/freeflowuniverse/crystallib

    crystal_web_get

    
}


function crystal_web_get {
    
    mkdir -p ~/.vmodules/freeflowuniverse/
    mkdir -p $DIR_CODE/github/freeflowuniverse
    if [[ -d "$DIR_CODE/github/freeflowuniverse/webcomponents" ]]
    then
        pushd $DIR_CODE/github/freeflowuniverse/webcomponents 2>&1 >> /dev/null     
        if [[ -z "$sshkeys" ]]; then
            echo
        else
            git remote set-url origin git@github.com:freeflowuniverse/webcomponents.git
        fi               
        popd 2>&1 >> /dev/null
    else
        pushd $DIR_CODE/github/freeflowuniverse 2>&1 >> /dev/null
        if [[ -z "$sshkeys" ]]; then
            git clone --depth 1 --no-single-branch https://github.com/freeflowuniverse/webcomponents
        else
            git clone --depth 1 --no-single-branch git@github.com:freeflowuniverse/webcomponents.git
        fi        
        popd 2>&1 >> /dev/null || exit
    fi

    mkdir -p ~/.vmodules/freeflowuniverse
    rm -f ~/.vmodules/freeflowuniverse/webcomponents
    ln -s "$DIR_CODE/github/freeflowuniverse/webcomponents/webcomponents" ~/.vmodules/freeflowuniverse/webcomponents

}


function crystal_pull {
    crystal_lib_get
    pushd $DIR_CODE/github/freeflowuniverse/crystallib
    git pull
    git checkout $CLBRANCH
    popd 2>&1 >> /dev/null
    pushd $DIR_CODE/github/freeflowuniverse/webcomponents
    git pull
    popd 2>&1 >> /dev/null
}

function crystal_test {
    set -ex
    pushd $DIR_CODE/github/freeflowuniverse/crystallib
    # v -enable-globals -stats test crystallib/core/pathlib
    v -enable-globals -stats test crystallib/core/texttools
    v -enable-globals -stats test crystallib/core/playbook
    v -enable-globals -stats test crystallib/data/encoder
    v -enable-globals -stats test crystallib/data/currency
    # v -enable-globals -stats test crystallib/data/markdownparser
    v -enable-globals -stats test crystallib/data/ourtime
    v -enable-globals -stats test crystallib/data/paramsparser
    # v -enable-globals -stats test crystallib/data/doctree
    popd 2>&1 >> /dev/null
}

