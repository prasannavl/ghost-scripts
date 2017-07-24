#!/usr/bin/env bash
## Author: Prasanna V. Loganathar

# The dir name for ghost inside the user's home dir
GHOST_DIR_NAME="${GHOST_DIR_NAME:-workspace}"

# The dir name where the git bare repo will be created.
# This is where remotes can push to.
GHOST_GIT_TARGET_NAME="${GHOST_GIT_TARGET_NAME:-ghost.git}"

# The dir name where the git checkout will happen by
# default after a remote pushes into the repo.
GHOST_GIT_CHECKOUT_NAME="${GHOST_GIT_CHECKOUT_NAME:-ghost-checkout}"

# The name of the deploy script that should be in the checkout
# for automatic deploy
GHOST_GIT_DEPLOY_SCRIPT="${GHOST_GIT_BUILD_FILE:-scripts/deploy.sh}"

ghost_init_bash_path() {
    if ! [ "$BASH_INIT_PATH" ]; then
        echo "export BASH_INIT_PATH=\"${PATH}\"" >> ~/.profile
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

ghost_install_golang() {
    echo "> install golang"
    
    local version="${GHOST_GOVERSION:-1.8.3}";
    local arch="${GHOST_GOARCH:-amd64}"
    local os="${GHOST_GOOS:-linux}"

    local work_dir="${HOME}/${GHOST_DIR_NAME}"

    local go_path="${work_dir}/golang"
    local go_root="${HOME}/opt/go${version}"
    local tmp="${work_dir}/tmp"

    local file_name="go${version}.${os}-${arch}.tar.gz"
    local url=https://storage.googleapis.com/golang/${file_name}

    local go_package="${tmp}/${file_name}"

    mkdir -p {"$tmp","$go_path","$go_root"}
    wget -c -O "$go_package" "$url"
    rm -rf "$go_root/*"
    tar -xf "$go_package" -C "$go_root" --strip-components=1
    # rm "$go_package"

    echo "export PATH=\"\$PATH:${go_root}/bin:${go_path}/bin\" # +ghost:path:go" >> ~/.profile
    echo "export GOROOT=\"${go_root}\" # +ghost:goroot" >> ~/.profile
    echo "export GOPATH=\"${go_path}\" # +ghost:gopath" >> ~/.profile

    export PATH="$PATH:${go_root}/bin:${go_path}/bin" >> ~/.profile
    export GOROOT="${go_root}" >> ~/.profile
    export GOPATH="${go_path}" >> ~/.profile
}

ghost_ensure_golang() {
    if ! [ "$GOROOT" ]; 
    then
        ghost_install_golang
    fi;
}

ghost_cleanup_golang() {
    echo "> cleanup golang"
    local go_root="${GOROOT}"
    sed -i "/\+ghost\(:path:go\|:goroot\|:gopath\)/d" ~/.profile
    rm -rf "${go_root}"
    unset GOPATH
    unset GOROOT
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

ghost_init_bare_repo() {
    echo "> init git bare repo"
    local work_dir="${HOME}/${GHOST_DIR_NAME}"
    local repo_dir="${work_dir}/${GHOST_GIT_TARGET_NAME}"
    git --git-dir "${repo_dir}" init --bare
    ghost_init_repo_post_receive
}

ghost_init_repo_post_receive() {
    local work_dir="${HOME}/${GHOST_DIR_NAME}"
    local repo_dir="${work_dir}/${GHOST_GIT_TARGET_NAME}"
    local checkout_dir="${work_dir}/${GHOST_GIT_CHECKOUT_NAME}"    
    local deploy_script="${GHOST_GIT_DEPLOY_SCRIPT}"
    local post_receive_file="${repo_dir}/hooks/post-receive"

    if ! [ -f "${post_receive_file}" ]; 
    then
        echo "> init git repo: post-receive"
    
        touch "${post_receive_file}"
        local deploy_file="${checkout_dir}/${deploy_script}"
        tee "${post_receive_file}" <<- EOF
#!/usr/bin/env bash
set -e
mkdir -p "${checkout_dir}"
cd "${checkout_dir}"
git --git-dir "${repo_dir}" --work-tree "${checkout_dir}" checkout -f
if [ -f "$deploy_file" ]; 
then
    cd "$checkout_dir"
    chmod +x "$deploy_file"    
    "${deploy_file}"
fi;
EOF
    fi;
    chmod +x "${post_receive_file}"
}

ghost_cleanup_bare_repo() {
    echo "> cleanup git bare repo"    
    local work_dir="${HOME}/${GHOST_DIR_NAME}"    
    local repo_dir="${work_dir}/ghost.git"
    rm -rf "$repo_dir"
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

ghost_configure_ssh_env() {
    local sshd_config="/etc/ssh/sshd_config"
    if [ $(grep -E "^\s*PermitUserEnvironment\s+" ${sshd_config}) ]; then
        if ! [ $(grep -E "^\s*PermitUserEnvironment\s+yes" ${sshd_config}) ]; then
            echo "> modifying sshd config - PermitUserEnvironment"        
            sed -r "s/(^\s*PermitUserEnvironment\s+)(.*)/\1yes/" ${sshd_config} | sudo tee ${sshd_config} > /dev/null
            ghost_configure_restart_sshd
        fi;
        return
    fi;
    echo "> adding sshd config - PermitUserEnvironment"
    printf "\r\nPermitUserEnvironment yes\r\n" | cat ${sshd_config} - | sudo tee ${sshd_config} > /dev/null
    ghost_configure_restart_sshd
}

ghost_configure_restart_sshd() {
    echo "> restarting sshd"
    sudo systemctl restart sshd     
}

ghost_run_init() {
    echo "> ghost: init start"
    ghost_configure_ssh_env
    ghost_ensure_essentials
    ghost_ensure_golang
    # ghost_ensure_node
    ghost_ensure_mongo
    ghost_configure_mongo_autostart
    ghost_configure_mongo_restart_on_failure
    ghost_init_bare_repo
    echo "> ghost: init done"
}