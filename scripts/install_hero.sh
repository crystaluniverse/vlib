#!/usr/bin/env bash
set -e

rm -f ${HOME}/.env.sh

touch ~/.profile

# remove_include_shell() {
#     for file in "$@"; do
#         if [[ -f "$file" ]]; then
#             sed -i '' '/env\.sh/d' "$file"
#             sed -i '' '/hero\/bin/d' "$file"
#             echo 'export PATH="$HOME/hero/bin:$PATH"' >> "$file"
#         fi
#     done
# }

# remove_include_shell "$HOME/.zprofile" "$HOME/.bashrc" "$HOME/.profile" "$HOME/.config/fish/config.fish" "$HOME/.zshrc"

if [[ -z "${CLBRANCH}" ]]; then 
    export CLBRANCH="development"
fi

if [ -z "$TERM" ]; then
    export TERM=xterm
fi
export OURHOME="$HOME/hero"
export DIR_BASE="$HOME"
export DIR_BUILD="/tmp"
export DIR_CODE="$DIR_BASE/code"
export DIR_CODEWIKI="$OURHOME/codewiki"
export DIR_CODE_INT="$HOME/_code"
export DIR_BIN="$OURHOME/bin"
export DIR_SCRIPTS="$OURHOME/bin"

export DEBIAN_FRONTEND=noninteractive

mkdir -p $DIR_BASE
mkdir -p $DIR_CODE
mkdir -p $DIR_CODE_INT
mkdir -p $DIR_BUILD
mkdir -p $DIR_BIN
mkdir -p $DIR_SCRIPTS

echo "DIRCODE: ${DIR_CODE}"


pathmunge () {
    if ! echo "$PATH" | grep -Eq "(^|:)$1($|:)" ; then
        if [ "$2" = "after" ] ; then
            PATH="$PATH:$1"
        else
            PATH="$1:$PATH"
        fi
    fi
}

pathmunge $DIR_BIN
pathmunge $DIR_SCRIPTS
pathmunge $DIR_BUILD

#keys used to see how to checkout code, don't remove
if [[ -z "$SSH_AUTH_SOCK" ]]; then
    echo " - SSH agent is not running."
    export sshkeys=''
else 
    export sshkeys=$(ssh-add -l)
fi



export DONE_DIR="$HOME/.done"
mkdir -p "$DONE_DIR"

# Generic function to execute a given function if the marker is older than one day
function execute_with_marker {
    local name=$1
    local func=$2
    local marker_file="$DONE_DIR/${name}_done"

    # Check if marker file exists and is older than one day
    if [ -f "$marker_file" ]; then
        if [ $(find "$marker_file" -mtime +1) ]; then
            echo "Marker file is older than one day. Removing it."
            rm "$marker_file"
        fi
    fi

    # Execute the function if the marker file does not exist
    if [ ! -f "$marker_file" ]; then
        $func
        if [ $? -eq 0 ]; then
            touch "$marker_file"
        fi
    else
        echo "${name} setup has already been completed."
    fi
}


is_github_actions() {
    [ -d "/home/runner" ] || [ -d "$HOME/runner" ]
}

set -x
if [ -n "$SUDO_USER" ]; then
    export HOME_SUDO=$(eval echo "~$SUDO_USER")
    SECRET_FILE="${HOME_SUDO}/mysecrets.sh"
    if [ -f "$SECRET_FILE" ]; then
        echo 'get secrets for sudoer'
        source "$SECRET_FILE"
    fi
fi

SECRET_FILE2="${HOME}/mysecrets.sh"
if [ -f "$SECRET_FILE2" ]; then
    echo 'get secrets for home user'
    source "$SECRET_FILE2"
fi


function myplatform {
    if [[ "${OSTYPE}" == "darwin"* ]]; then
        export OSNAME='darwin'
    elif [ -e /etc/os-release ]; then
        # Read the ID field from the /etc/os-release file
        export OSNAME=$(grep '^ID=' /etc/os-release | cut -d= -f2)
        if [ "${os_id,,}" == "ubuntu" ]; then
            export OSNAME="ubuntu"          
        fi
        if [ "${OSNAME}" == "archarm" ]; then
            export OSNAME="arch"          
        fi        
        if [ "${OSNAME}" == "debian" ]; then
            export OSNAME="ubuntu"          
        fi            
    else
        echo "Unable to determine the operating system."
        exit 1        
    fi


    # if [ "$(uname -m)" == "x86_64" ]; then
    #     echo "This system is running a 64-bit processor."
    # else
    #     echo "This system is not running a 64-bit processor."
    #     exit 1
    # fi    

}

function is_root {
    if [ "$(whoami)" != "root" ]; then
        echo "This script must be run as root or with sudo."
        exit 1
    fi

}

# Function to check if systemd is installed
function is_systemd_installed {
    [ "$(ps -p 1 -o comm=)" = "systemd" ]
}

# Function to check if init.d is installed
function is_initd_installed {
    [ -d /etc/init.d ]
}

function is_zinit_installed {
    [ "$(ps -p 1 -o comm=)" = "zinit" ]
}




myplatformid() {
    local arch=$(uname -m)
    local os=$(uname -s)

    case "$os" in
        Linux*)
            case "$arch" in
                aarch64|arm64) echo "linux-arm64" ;;
                x86_64) echo "linux-i64" ;;
                *) echo "unknown" ;;
            esac
            ;;
        Darwin*)
            case "$arch" in
                arm64) echo "macos-arm64" ;;
                x86_64) echo "macos-i64" ;;
                *) echo "unknown" ;;
            esac
            ;;
        *)
            echo "unknown"
            ;;
    esac
}


export MYPLATFORMID=$(myplatformid)

if [ "$MYPLATFORMID" == "unknown" ]; then
    echo "Error: Unable to detect platform" >&2
    exit 1
fi

function gitcheck {
    # Check if Git email is set
    if [ -z "$(git config user.email)" ]; then
        # If not set, prompt the user to enter it
        echo "Git email is not set."
        read -p "Enter your Git email: " git_email

        # Set the Git email
        git config --global user.email "$git_email"
        echo "Git email set to '$git_email'."
    else
        # Git email is already set
        echo "Git email is set to: $(git config user.email)"
    fi
}


function sshknownkeysadd {
    mkdir -p ~/.ssh
    touch ~/.ssh/known_hosts
    if ! grep github.com ~/.ssh/known_hosts > /dev/null
    then
        ssh-keyscan github.com >> ~/.ssh/known_hosts
    fi
    if ! grep git.ourworld.tf ~/.ssh/known_hosts > /dev/null
    then
        ssh-keyscan git.ourworld.tf >> ~/.ssh/known_hosts
    fi    
    git config --global pull.rebase false

}

# function mycommit {
#     gitcheck
#     # Check if we are inside a Git repository
#     if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
#         git_root=$(git rev-parse --show-toplevel)
#         echo "You are inside a Git repository $git_root."
#         pushd "$git_root"        
#     else
#         echo commit crystallib
#         pushd "$DIR_CODE/github/freeflowuniverse/crystallib"  2>&1 > /dev/null
#     fi
#     if [[ -z "$sshkeys" ]]; then
#         echo
#     else
#         git remote set-url origin git@github.com:freeflowuniverse/crystallib.git
#     fi          
#     if [[ $(git status -s) ]]; then
#         echo There are uncommitted changes.
#         git add . -A
#         echo "Please enter a commit message:"
#         read commit_message
#         git commit -m "$commit_message"
#         git pull
#         git push
#     else
#         echo "no changes"
#     fi
#     popd   2>&1 >/dev/null
# }






function package_check_install {
    local command_name="$1"
    if command -v "$command_name" >/dev/null 2>&1; then
        echo "command '$command_name' is already installed."
    else    
        package_install '$command_name'
    fi
}

function package_install {
    local command_name="$1"
    if [[ "${OSNAME}" == "ubuntu" ]]; then
        apt -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" install $1 -q -y --allow-downgrades --allow-remove-essential 
    elif [[ "${OSNAME}" == "darwin"* ]]; then
        brew install $command_name
    elif [[ "${OSNAME}" == "alpine"* ]]; then
        apk add $command_name
    elif [[ "${OSNAME}" == "arch"* ]]; then
        pacman --noconfirm -Su $command_name
    else
        echo "platform : ${OSNAME} not supported"
        exit 1
    fi
}
function myexecdownload() {
    local script_name="$1"
    local download_url="$2"
    
    # Check if the script exists in the current directory
    if [ -f "./$script_name" ]; then
        echo "Script '$script_name' already exists in the current directory."
    else
        # Attempt to download the script
        echo "Script '$script_name' not found. Downloading from '$download_url'..."
        if curl -o "./$script_name" -s "$download_url"; then
            echo "Download successful. Script '$script_name' is now available in the current directory."
            chmod +x "./$script_name" # Make the script executable if needed
        else
            echo "Error: Download failed. Script '$script_name' could not be downloaded."
            exit 1
        fi
    fi
}

function myexec() {
    local script_name="$1"
    local download_url="$2"
    myexecdownload "$1" "$2"
    bash "${script_name}"
}

function reset {
    if [[ -n "${FULLRESET}" ]]; then
        echo " - FULLRESET"
        rm -rf ~/.vmodules
        rm -rf ~/code  
        rm -rf $DONE_DIR
        mkdir -p  $DONE_DIR
    fi  

    if [[ -n "${RESET}" ]]; then
        echo " - RESET"
        rm -rf ~/.vmodules
        rm -rf $DONE_DIR
        mkdir -p  $DONE_DIR        
    fi  

}
function check_for_oneshot {
	for arg in "$@"; do
		if [ "$arg" = "-oneshot" ]; then
			echo "Found '-oneshot' argument."
			return 0 # Indicates success (found)
		fi
	done
	return 1 # Indicates failure (not found)
}

function zinit_add {
	local script_name="$1"
    local cmd="$2"
	local cmdtest="$3"
	rm -f "/etc/zinit/cmds/${script_name}.sh"
	rm -f "/etc/zinit/${script_name}.yaml"
	mkdir -p /etc/zinit/cmds
	mkdir -p /etc/zinit/cmdstest
	if [[ -n ${cmd} ]]; then
		echo "${cmd}" >"/etc/zinit/cmds/${script_name}.sh"
		chmod 770 "/etc/zinit/cmds/${script_name}.sh"
	fi
	if [[ -n ${cmdtest} ]]; then
		mkdir -p /etc/zinit/cmdstest
		echo "${cmdtest}" >"/etc/zinit/cmdstest/${script_name}.sh"
		chmod 770 "/etc/zinit/cmdstest/${script_name}.sh"
	fi
	echo "${zinitcmd}" >"/etc/zinit/${script_name}.yaml"
	if [[ -n ${cmd} ]]; then
		echo "exec: bash -c \"/etc/zinit/cmds/${script_name}.sh\"" >>"/etc/zinit/${script_name}.yaml"
	fi
	if [[ -n ${cmdtest} ]]; then
		echo "test: bash -c \"/etc/zinit/cmdstest/${script_name}.sh\"" >>"/etc/zinit/${script_name}.yaml"
	fi
	if check_for_oneshot "$@"; then
		echo "oneshot: true" >>"/etc/zinit/${script_name}.yaml"
	fi
}

function zinit_install {

	if [[ "$(uname -m)" == "x86_64" ]]; then
		echo "This system is running an intel/amd 64-bit processor."
	else
		echo "This system is not running an intel/amd  64-bit processor."
		exit 1
	fi

	rm -f /usr/local/bin/zinit
	curl https://github.com/freeflowuniverse/freeflow_binary/raw/main/x86_64/zinit /usr/local/bin/zinit

	file_url="https://github.com/freeflowuniverse/freeflow_binary/raw/main/x86_64/zinit"
	destination_dir="/usr/local/bin"
	destination_tmp_path="/tmp/zinit0"
	destination_path="$destination_dir/zinit"
	min_file_size=$((5 * 1024 * 1024))

	curl -o "$destination_tmp_path" -L "$file_url"
	if [ $? -eq 0 ]; then
		file_size=$(stat -c%s "$destination_tmp_path")
		if [ "$file_size" -gt "$min_file_size" ]; then
			echo "Downloaded file is larger than 5MB."
			echo "Moving the file to $destination_path."
			rm -f destination_path
			mv "$destination_tmp_path" "$destination_path"
			if [ $? -eq 0 ]; then
				echo "File moved successfully."
			else
				echo "Error: Unable to move the file."
				exit 1
			fi
		else
			echo "Downloaded file is not larger than 5MB."
			exit 1
		fi
	else
		echo "Error: Unable to download the file."
		exit 1
	fi

	chmod 770 $destination_path

	mkdir -p /etc/zinit/

}

function initdinstall {

	if [[ ${OSTYPE} == "linux-gnu"* ]]; then
		local script_name="$1"
		local cmd="$2"
		servicefile="
[Unit]
Description=${script_name}
After=network.target 

[Service]
Type=simple
ExecStart=$cmd
WorkingDirectory=/tmp
Restart=always

[Install]
WantedBy=multi-user.target
"
		spath="/etc/systemd/system/${script_name}.service"
		rm -f $spath
		echo "$servicefile" >$spath
		systemctl daemon-reload
		systemctl enable $script_name
		systemctl start $script_name
	fi
}

function checkzinit {
	zinit list 2>&1 >/dev/null
}

#get it in initd or other way
#to check :     tmux attach-session -t zinit
function zinitinit {
	if ! [[ ${OSTYPE} == "linux-gnu"* ]]; then
		echo "only support linux"
		exit 1
	fi
	(checkzinit)
	if [ $? -ne 0 ]; then
		#### zinit kill
		tmux_session="zinit"
		if tmux has-session -t "$tmux_session" &>/dev/null; then
			# If the session exists, check if the window exists
			if tmux list-windows -t "$tmux_session" | grep -q "$tmux_window"; then
				# If the window exists, kill it
				tmux kill-window -t "$tmux_session:$tmux_window"
			fi
		fi
		if pgrep zinit >/dev/null; then
			# If running, kill Redis server
			echo "zinit is running. Stopping..."
			pkill zinit
			echo "zinit server has been stopped."
		else
			echo "zinit server is not running."
		fi
		if [ -x "$(command -v systemctl)" ]; then
			echo "systemctl is installed."
			initdinstall "zinit" "zinit init"
		else
			echo "initd is not installed."
			zinittmuxinit
		fi
		echo "zinit installed ok"
	fi

}

# #!/bin/bash
# function zinittmuxinit {
# 	# Specify the name of the tmux session and window
# 	tmux_session="zinit"
# 	tmux_window="zinit"
# 	command_to_execute="zinit init"
# 	# Check if tmux is installed
# 	if ! command -v tmux &>/dev/null; then
# 		echo "tmux is not installed. Please install it before running this script."
# 		exit 1
# 	fi
# 	# Check if the tmux session exists
# 	if tmux has-session -t "$tmux_session" &>/dev/null; then
# 		# If the session exists, check if the window exists
# 		if tmux list-windows -t "$tmux_session" | grep -q "$tmux_window"; then
# 			# If the window exists, kill it
# 			tmux kill-window -t "$tmux_session:$tmux_window"
# 		fi
# 	fi
# 	# Start a new tmux session with the desired window and execute the command
# 	tmux new-session -d -s "$tmux_session" -n "$tmux_window"
# 	tmux send-keys -t "$tmux_session:$tmux_window" "$command_to_execute" C-m
# 	echo "Started a new tmux session with window '$tmux_window' and executed '$command_to_execute'."
# }

function os_update {
    echo ' - os update'
    if [[ "${OSNAME}" == "ubuntu" ]]; then
        if is_github_actions; then
            echo "github actions"
        else
            rm -f /var/lib/apt/lists/lock
            rm -f /var/cache/apt/archives/lock
            rm -f /var/lib/dpkg/lock*		
        fi    
        export TERM=xterm
        export DEBIAN_FRONTEND=noninteractive
        dpkg --configure -a
        apt update -y
        if is_github_actions; then
            echo "** IN GITHUB ACTIONS, DON'T DO UPDATE"
        else
            set +e
            echo "** UPDATE"
            apt-mark hold grub-efi-amd64-signed
            set -e
            apt upgrade  -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
            apt autoremove  -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
        fi 
        #apt install apt-transport-https ca-certificates curl software-properties-common  -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
        package_install "apt-transport-https ca-certificates curl wget software-properties-common tmux"
        package_install "rclone rsync mc redis-server screen net-tools git htop ca-certificates lsb-release binutils pkg-config"

    elif [[ "${OSNAME}" == "darwin"* ]]; then
        if command -v brew >/dev/null 2>&1; then
            echo 'homebrew installed'
        else 
            export NONINTERACTIVE=1
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"            
            unset NONINTERACTIVE
        fi
        set +e
        brew install mc redis curl tmux screen htop wget rclone
        set -e
    elif [[ "${OSNAME}" == "alpine"* ]]; then
        apk update screen git htop tmux
        apk add mc curl rsync htop redis bash bash-completion screen git rclone
        sed -i 's#/bin/ash#/bin/bash#g' /etc/passwd             
    elif [[ "${OSNAME}" == "arch"* ]]; then
        pacman -Syy --noconfirm
        pacman -Syu --noconfirm
        pacman -Su --noconfirm arch-install-scripts gcc mc git tmux curl htop redis wget screen net-tools git sudo htop ca-certificates lsb-release screen rclone

        # Check if builduser exists, create if not
        if ! id -u builduser > /dev/null 2>&1; then
            useradd -m builduser
            echo "builduser:$(openssl rand -base64 32 | sha256sum | base64 | head -c 32)" | chpasswd
            echo 'builduser ALL=(ALL) NOPASSWD: ALL' | tee /etc/sudoers.d/builduser
        fi

        if [[ -n "${DEBUG}" ]]; then
            execute_with_marker "paru_install" paru_install
        fi
    fi
    echo 'os_update done'
}

function paru_install {
    echo ' - paru install'
    pushd /tmp
    pacman -S --needed --noconfirm base-devel git
    rm -rf paru
    git clone https://aur.archlinux.org/paru.git
    chown -R builduser:builduser paru

    # Switch to the regular user to build and install the package
    -u builduser bash <<EOF
    popd /tmp/paru
    rustup default stable
    makepkg -si --noconfirm
EOF
    

    # Go back to the original user
    popd
    popd

}

function redis_start {
    set +ex
    echo 'REDIS START'
    if redis-cli ping | grep -q "PONG"; then
        echo "Redis is already running."
        return
    fi    
    set -e

    if [[ "${OSNAME}" == "darwin"* ]]; then
        brew services start redis
        sleep 0.2
    # elif [[ "${OSNAME}" == "arch"* ]]; then
    #     redis-server --daemonize yes
    else
        if [[ "${OSNAME}" == "arch"* ]]; then
            RNAME='redis'
        else
            RNAME='redis-server'
        fi
        # Enable and start Redis service using the appropriate service manager
        if is_systemd_installed; then
            echo "Using systemd to manage Redis."
            systemctl enable ${RNAME}
            systemctl start ${RNAME}
        elif is_initd_installed; then
            echo "Using init.d to manage Redis."
            update-rc.d redis-server defaults
            service redis-server start
            #/etc/init.d/redis-server start                
        elif is_zinit_installed; then
            echo "Using zinit to manage Redis."
            echo 'exec: bash -c "/usr/bin/redis-server"' > /etc/zinit/redis.yaml
            zinit monitor redis
            zinit start redis
        else
            redis-server --daemonize yes
            # echo "Neither systemd nor init.d is installed. Cannot manage Redis service."
            # exit 1
        fi

    fi

    redis_test

}


function redis_test {
    if redis-cli ping | grep -q "PONG"; then
        echo "Redis is running and responsive."
    else
        echo "Redis is not responding to PING."
        exit 1
    fi
}


function v_install {
    set -e
    echo "v install"
    if [[ -z "${DIR_CODE_INT}" ]]; then 
        echo 'Make sure to source env.sh before calling this script.'
        exit 1
    fi
    if [ -d "$HOME/.vmodules" ]
    then
        if [[ -z "${USER}" ]]; then
            chown -R $USER:$USER ~/.vmodules
        else
            USER="$(whoami)"
            chown -R $USER ~/.vmodules
        fi
    fi

	if [[ ${OSNAME} == "ubuntu"* ]]; then
		package_install "libgc-dev gcc make libpq-dev"
	elif [[ ${OSNAME} == "darwin"* ]]; then
		brew install bdw-gc
	elif [[ ${OSNAME} == "alpine"* ]]; then
		package_install "make gcc libc-dev gcompat libstdc++"
	elif [[ ${OSNAME} == "arch" ]]; then
		package_install "make tcc"
	else
		echo "ONLY SUPPORT OSX AND LINUX FOR NOW"
		exit 1
	fi

    if [[ -d "$DIR_CODE_INT/v" ]]; then
        pushd $DIR_CODE_INT/v
        git pull
        popd "$@" > /dev/null
    else
        mkdir -p $DIR_CODE_INT
        pushd $DIR_CODE_INT
        rm -rf $DIR_CODE_INT/v
        git clone  --depth 1  https://github.com/vlang/v
        popd "$@" > /dev/null
    fi

    pushd $DIR_CODE_INT/v
    make

    if [[ ${OSNAME} == "darwin"* ]]; then
        mkdir -p ${HOME}/hero/bin
        rm -f ${HOME}/hero/bin/v
        ln -s ${DIR_CODE_INT}/v/v ${HOME}/hero/bin/v
        popd "$@" > /dev/null
        export PATH="${HOME}/hero/bin:$PATH"
	else
        ${DIR_CODE_INT}/v/v symlink
    fi


    if ! [ -x "$(command -v v)" ]; then
    echo 'ERROR: vlang is not installed.' >&2
    exit 1
    fi
}


function v_analyzer_install {

    if is_github_actions; then
        return
    fi

    if [[ -n "${DEBUG}" ]]; then
        v -e "$(curl -fsSL https://raw.githubusercontent.com/vlang/v-analyzer/main/install.vsh)"
    fi  
    # set -x
    # pushd /tmp
    # source ~/.profile
    # rm -f install.sh
    # curl -fksSL https://raw.githubusercontent.com/v-analyzer/v-analyzer/master/install.vsh > install.vsh
    # v run install.vsh  --no-interaction
    # popd "$@" > /dev/null
    # # set +x
}
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




function hero_install {
    set -e
    
    redis_start

    os_name="$(uname -s)"
    arch_name="$(uname -m)"

    # Select the URL based on the platform
    if [[ "$os_name" == "Linux" && "$arch_name" == "x86_64" ]]; then
        url="https://f003.backblazeb2.com/file/threefold/linux-i64/hero"
    elif [[ "$os_name" == "Darwin" && "$arch_name" == "arm64" ]]; then
        url="https://f003.backblazeb2.com/file/threefold/macos-arm64/hero"
    # elif [[ "$os_name" == "Darwin" && "$arch_name" == "x86_64" ]]; then
    #     url="https://f003.backblazeb2.com/file/threefold/macos-i64/hero"
    else
        echo "Unsupported platform."
        exit 1
    fi

    if [[ "${OSNAME}" == "darwin"* ]]; then
        [ -f /usr/local/bin/hero ] && rm /usr/local/bin/hero
    fi

    if [ -z "$url" ]; then
        echo "Could not find url to download."
        echo $urls
        exit 1
    fi
    zprofile="${HOME}/.zprofile"
    hero_bin_path="${HOME}/hero/bin"
    temp_file="$(mktemp)"

    # Check if ~/.zprofile exists
    if [ -f "$zprofile" ]; then
        # Read each line and exclude any that modify the PATH with ~/hero/bin
        while IFS= read -r line; do
            if [[ ! "$line" =~ $hero_bin_path ]]; then
                echo "$line" >> "$temp_file"
            fi
        done < "$zprofile"
    else
        touch "$zprofile"
    fi
    # Add ~/hero/bin to the PATH statement
    echo "export PATH=\$PATH:$hero_bin_path" >> "$temp_file"
    # Replace the original .zprofile with the modified version
    mv "$temp_file" "$zprofile"
    # Ensure the temporary file is removed (in case of script interruption before mv)
    trap 'rm -f "$temp_file"' EXIT

    # Output the selected URL
    echo "Download URL for your platform: $url"

    # Download the file
    curl -o /tmp/downloaded_file -L "$url"

    # Check if file size is greater than 10 MB
    file_size=$(du -m  /tmp/downloaded_file | cut -f1)
    if [ "$file_size" -ge 10 ]; then
        # Create the target directory if it doesn't exist
        mkdir -p ~/hero/bin
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Move and rename the file
            mv  /tmp/downloaded_file ~/hero/bin/hero
            chmod +x ~/hero/bin/hero
        else
            mv  /tmp/downloaded_file /usr/local/bin/hero
            chmod +x /usr/local/bin/hero
        fi

        echo "Hero installed properly"
        export PATH=$PATH:$hero_bin_path
        hero -version
    else
        echo "Downloaded file is less than 10 MB. Process aborted."
        exit 1
    fi
}

# function get_rclone_config() {
#     for conf in "/root/.config/rclone/rclone.conf" "${HOME}/.config/rclone/rclone.conf"; do
#         [[ -f "$conf" ]] && echo "$conf" && return 0
#     done
#     echo "Error: No rclone configuration file found" >&2
#     return 1
# }

function hero_upload {
    set -e    
    hero_path=$(which hero 2>/dev/null)
    if [ -z "$hero_path" ]; then
        echo "Error: 'hero' command not found in PATH" >&2
        exit 1
    fi
    set -x
    s3_configure
    # rclone_config=$(get_rclone_config) || { echo "$rclone_config"; exit 1; }
    rclone --config="${HOME}/.config/rclone/rclone.conf" lsl b2:threefold/$MYPLATFORMID/
    rclone --config="${HOME}/.config/rclone/rclone.conf" copy "$hero_path" b2:threefold/$MYPLATFORMID/
}
    


function s3_configure {

SECRET_FILE="/${HOME}/code/git.ourworld.tf/despiegk/hero_secrets/mysecrets.sh"
if [ -f "$SECRET_FILE" ]; then
    echo get secrets
    source "$SECRET_FILE"
fi    

# Check if environment variables are set
if [ -z "$S3KEYID" ] || [ -z "$S3APPID" ]; then
    echo "Error: S3KEYID or S3APPID is not set"
    exit 1
fi

# Create rclone config file
mkdir -p "${HOME}/.config/rclone"
cat > "${HOME}/.config/rclone/rclone.conf" <<EOL
[b2]
type = b2
account = $S3KEYID
key = $S3APPID
hard_delete = true
EOL

echo "made S3 config on: ${HOME}/.config/rclone/rclone.conf"

cat ${HOME}/.config/rclone/rclone.conf

}


function freeflow_dev_env_install {

    set -ex

    crystal_lib_get

    if ! [ -x "$(command -v v)" ]; then
        v_install
    fi
    if ! [ -x "$(command -v redis-cli)" ]; then
        echo "CANNOT FIND REDIS-SERVER"
    exit 1
    fi

    #~/code/github/freeflowuniverse/crystallib/scripts/package.vsh

    local response=$(redis-cli PING)

    # Check if the response is PONG
    if [[ "${response}" == "PONG" ]]; then
        echo "REDIS OK"
    else
        echo "REDIS CLI INSTALLED BUT REDIS SERVER NOT RUNNING" 
        exit 1
    fi

}


function hero_build {

    freeflow_dev_env_install

    echo " - compile hero"
    ~/code/github/freeflowuniverse/crystallib/cli/hero/compile.sh
    source ~/.profile

    hero init -d

}


myplatform

#check if reset should be done
reset

execute_with_marker "os_update" os_update

redis_start

sshknownkeysadd




hero_install
echo 'INSTALL HERO OK'
