#!/usr/bin/env bash
## Author: Prasanna V. Loganathar

# The dir name where the git bare repo will be created.
# This is where remotes can push to.
GHOST_GIT_TARGET_NAME="${GHOST_GIT_TARGET_NAME:-ghost}"

# The dir name where the git checkout will happen by
# default after a remote pushes into the repo.
GHOST_GIT_CHECKOUT_NAME="${GHOST_GIT_CHECKOUT_NAME:-ghost-checkout}"

# The name of the deploy script that should be in the checkout
# for automatic deploy
GHOST_GIT_DEPLOY_SCRIPT="${GHOST_GIT_BUILD_FILE:-scripts/deploy.sh}"

ghost_init_repo() {
    echo "> init git bare repo"
    local work_dir="${HOME}/${GHOST_DIR_NAME}"
    local repo_dir="${work_dir}/${GHOST_GIT_TARGET_NAME}"
    git --git-dir "${repo_dir}" init --bare
    ghost_init_repo_postreceive
}

ghost_init_repo_postreceive() {
    # TODO: Add race condition handling to post-receive scripts, 
    # with graceful exit of previous script
    
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
set -i
source "${HOME}/.profile"
set -e
rm -rf "${checkout_dir}" || true
mkdir -p "${checkout_dir}" || true
cd "${checkout_dir}"
git --git-dir="${repo_dir}" --work-tree="${checkout_dir}" checkout -f
if [ -f "$deploy_file" ]; 
then
    cd "$checkout_dir"
    chmod +x "$deploy_file"
    "${deploy_file}"
fi;
EOF
    fi;
    chmod +x "$post_receive_file"
}

ghost_cleanup_repo_postreceive() {
    local work_dir="${HOME}/${GHOST_DIR_NAME}"
    local repo_dir="${work_dir}/${GHOST_GIT_TARGET_NAME}"
    local post_receive_file="${repo_dir}/hooks/post-receive"
    echo "> cleanup git repo postreceive: " $post_receive_file
    rm -f "$post_receive_file"
}

ghost_cleanup_repo() {
    local work_dir="${HOME}/${GHOST_DIR_NAME}"
    local repo_dir="${work_dir}/${GHOST_GIT_TARGET_NAME}"
    echo "> cleanup git repo: " $repo_dir
    rm -rf "$repo_dir"
}

ghost_cleanup_repo_full() {
    local work_dir="${HOME}/${GHOST_DIR_NAME}"
    local checkout_dir="${work_dir}/${GHOST_GIT_CHECKOUT_NAME}"
    echo "> cleanup git checkout: " $checkout_dir
    rm -rf "$checkout_dir"
    ghost_cleanup_repo  
}