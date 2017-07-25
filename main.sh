#!/usr/bin/env bash
## Author: Prasanna V. Loganathar

# The dir name for ghost inside the user's home dir
GHOST_DIR_NAME="${GHOST_DIR_NAME:-workspace}";

ghost_run_main() {
    local ghost_dir=$(dirname "${0}")
    source ${ghost_dir}/init.sh
    source ${ghost_dir}/pull.sh
    if [[ $# -ne 0 ]]; then ghost_main_parse_and_exec "$@"; fi;    
}

ghost_run_remote() {
    echo "> remote run";
    
    if [[ $# -lt 4 ]]; then
        echo "invalid arguments for remote run" 
        exit 1;
    fi;

    local host=$2
    local i;
    for ((i=3;i<$#;i++)) # start at 2 to skip the first 2 args
    do
        local x=${!i};
        if [ $x == "--" ]; then local _ARG_CMD="1"; break; fi;
    done

    local lx1=i+1
    local lx2=i-2

    local cmd=${@:$lx1}
    local ssh_args=${@:2:$lx2}

    echo "> remote-command: " $cmd
    echo "> ssh-args: " $ssh_args

    if ! [ $_ARG_CMD ]; then echo "> no remote command to execute"; return; fi;    

    local script_file="$0"
    local scripts_dir=$(dirname "${script_file}")
    local ghost_scripts_dir="${GHOST_DIR_NAME}/ghost-scripts"

    find . -not -path "./.git*" -path "*.sh" | xargs tar czf - | ssh ${ssh_args} "rm -rf \"${ghost_scripts_dir}\" && mkdir -p \"${ghost_scripts_dir}\" && tar xzf - -C \"${ghost_scripts_dir}\" && source .profile && \"${ghost_scripts_dir}/main.sh\" ${cmd}"
}

ghost_main_usage() {
    printf "\r\nUsage:\r\n\r\n"
    echo "$0 init"
    echo "$0 pull [--repo GHOST_REPO] [--name GHOST_DEPLOY_NAME] [--commit commit_sha1]"
    # echo "$0 build [--name GHOST_DEPLOY_NAME]"
    # echo "$0 run [--name GHOST_DEPLOY_NAME]"
    echo "$0 remote <ssh-host> <ssh-options> -- <command>"
    printf "\r\n"
}

ghost_main_parse_and_exec() {
    # exit on error    
    set -e
    case "$1" in
        "init")
        ghost_run_init "$@"
        ;;
        "pull")
        ghost_run_pull "$@"
        ;;
        "remote")
        ghost_run_remote "$@"
        ;;
        "exec")
        local cmd=${@:1}
        local ext_cmd=$(echo "$cmd" | sed -r "s/^exec\s(.*)/\1/")
        "$ext_cmd"
        ;;
        *)
        ghost_main_usage
        ;;
    esac
}

ghost_run_main "$@"