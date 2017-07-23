#!/usr/bin/env bash
## Author: Prasanna V. Loganathar

# The dir name for ghost inside the user's home dir
GHOST_DIR_NAME="${GHOST_DIR_NAME:-workspace}";

# The source repository to be used for
# deployment
GHOST_GIT_REPO_PULL_URL="${GHOST_REPO}";

# Name of the deployment
GHOST_DEPLOY_NAME="${GHOST_DEPLOY_NAME:-ghost-src}";

ghost_git_clone() {
    local work_dir=~/${1:-$GHOST_DIR_NAME}
    local git_repo=${2:-$GHOST_GIT_REPO_PULL_URL}
    local git_deploy_name=${3:-$GHOST_DEPLOY_NAME}
    local git_sha=${4}

    rm -rf "${work_dir}/${git_deploy_name}"
    mkdir -p "${work_dir}"
    cd "${work_dir}"
    if ! [ $git_sha ];
    then 
        git clone --depth=1 "${git_repo}" "${work_dir}/${git_deploy_name}"
    else
        git clone "${git_repo}" "${work_dir}/${git_deploy_name}"
        git checkout "${git_sha}"
    fi;
    cd "${work_dir}/${git_deploy_name}"
}

ghost_run_pull() {
    local name;
    local repo;
    local commit;
    
    local i;
    for ((i=2;i<$#;i++)) # start at 2 to skip the first 2 args
    do
        local x=${!i}
        local nx=$(($i+1))
        case "$x" in
            "--name") name=${!nx}
            ;;
            "--repo") repo=${!nx}
            ;;
            "--commit") commit=${!nx}
            ;;
        esac
    done

    ghost_git_clone "$GHOST_DIR_NAME" "$repo" "$name" "$commit"
}