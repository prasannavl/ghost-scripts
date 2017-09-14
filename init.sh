#!/usr/bin/env bash
## Author: Prasanna V. Loganathar

# The dir name for ghost inside the user's home dir
GHOST_DIR_NAME="${GHOST_DIR_NAME:-.}"

ghost_init_bash_path() {
    if ! [ "$BASH_INIT_PATH" ]; then
        echo "export BASH_INIT_PATH=\"${PATH}\"" >> "${HOME}/.profile"
        export BASH_INIT_PATH="${PATH}"
    fi;
}

ghost_reset_bash_path() {
    export PATH="${BASH_INIT_PATH}"
}

ghost_ensure_essentials() {
    # install essentials
    ghost_init_bash_path
    sudo apt update && sudo apt install -y build-essential nano curl git mercurial make binutils bison gcc python tree mc htop
}

ghost_install_gvm() {
    echo "> install gvm"
    curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer | bash
    ghost_setup_gvm_env
}

ghost_setup_gvm_env() {
    echo "> setup gvm"
    [ -s "${HOME}/.gvm/scripts/gvm" ] && source "${HOME}/.gvm/scripts/gvm"
}

ghost_ensure_gvm() {
    if ! [ "$GVM_ROOT" ]; 
    then
        ghost_install_gvm
        ghost_setup_gvm_env
    fi;
}

ghost_install_golang() {
    echo "> install golang"
    local version="${GHOST_GOVERSION:-1.8.3}";
    ghost_ensure_gvm
    gvm install go${version} -B
    gvm use go${version} --default
}

ghost_ensure_golang() {
    if ! which go > /dev/null
    then 
        ghost_install_golang
    fi;
}

ghost_install_nvm() {
    echo "> install nvm"    
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
}

ghost_setup_nvm_env() {
    echo "> setup nvm"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

ghost_ensure_nvm() {
    if ! [ "$NVM_DIR" ]; 
    then
        ghost_install_nvm
        ghost_setup_nvm_env
    fi;
}

ghost_install_node() {
    echo "> install node"    
    ghost_ensure_nvm
    nvm install node
    nvm use node
}

ghost_ensure_node() {
    if ! which node > /dev/null
    then 
        ghost_install_node
    fi;
}

ghost_setup_mongo_repo() {
    # setup monogdb
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
    echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    # TODO: cleanup_mongo_repo 
}

ghost_install_mongo() {
    sudo apt-get update && sudo apt-get install -y mongodb-org    
}

ghost_ensure_mongo() {
    if ! which mongod > /dev/null
    then 
        echo "> setup mongodb repo"
        ghost_setup_mongo_repo
        echo "> install mongodb"
        ghost_install_mongo
    fi;
}

ghost_cleanup_temp() {
    echo "> cleanup temp"
    local work_dir="${HOME}/${GHOST_DIR_NAME}"
    rm -rf ${work_dir}/tmp/*
}

# ---
# Config
# ---

ghost_configure_mongo_autostart() {
    if [ $(systemctl is-enabled mongod) != "enabled" ];
    then
        echo "> enable mongod"
        sudo systemctl enable mongod
    fi;
}

ghost_configure_mongo_restart_on_failure() {
    if ! [ $(systemctl cat mongod | grep Restart=on-failure) ];
    then
        echo "> mongod: set Restart=on-failure"
        local FILENAME=/etc/systemd/system/mongod.service.d/override.conf
        if ! [ -f "$FILENAME" ]; 
        then
            sudo mkdir -p /etc/systemd/system/mongod.service.d 
            sudo touch "$FILENAME"
        fi;
        # sudo systemctl stop mongod
        if [ $(grep Restart "$FILENAME") ];
        then 
            echo "> mongod: modify exisiting 'Restart' value"
            sed s/Restart=.*$/Restart=on-failure/g "$FILENAME" | sudo tee "$FILENAME" > /dev/null
        else
            echo "> mongod: add new service config - Restart"        
            printf "\r\n[Service]\r\nRestart=on-failure\r\n" | sudo tee "$FILENAME" > /dev/null
        fi;
        sudo systemctl daemon-reload
        # sudo systemctl start mongod
    fi;
}

ghost_ensure_mongo_full() {
    ghost_ensure_mongo
    ghost_configure_mongo_autostart
    ghost_configure_mongo_restart_on_failure
}

ghost_run_init() {
    echo "> ghost: init start"
    ghost_ensure_essentials
    # ghost_ensure_golang
    # ghost_ensure_node
    # ghost_ensure_mongo_full
    echo "> ghost: init done"
}