#!/usr/bin/env bash
## Author: Prasanna V. Loganathar

ghost_install_golang_direct() {
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

    local profile_file="${HOME}/.profile"

    echo "export GOROOT=\"${go_root}\" # +ghost:goroot" >> "$profile_file"
    echo "export GOPATH=\"${go_path}\" # +ghost:gopath" >> "$profile_file"
    echo "export PATH=\"\$PATH:${go_root}/bin:${go_path}/bin\" # +ghost:path:go" >> "$profile_file"    

    export GOROOT="${go_root}"
    export GOPATH="${go_path}"  
    export PATH="$PATH:${go_root}/bin:${go_path}/bin"   
}

ghost_ensure_golang_direct() {
    if ! [ "$GOROOT" ]; 
    then
        ghost_install_golang
    fi;
}

ghost_cleanup_golang_direct() {
    echo "> cleanup golang"
    local go_root="${GOROOT}"
    sed -i "/\+ghost\(:path:go\|:goroot\|:gopath\)/d" "${HOME}/.profile"
    rm -rf "${go_root}"
    unset GOPATH
    unset GOROOT
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