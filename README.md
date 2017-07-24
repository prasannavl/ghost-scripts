### Ghost

Build scripts for friction-free manual deployment.

- Brings Ubuntu-based machines from bare to full production environment with a simple ssh.
- Transfers and updates itself on each `remote` run to the targets.
- Sets up bare git repo, and makes itself a `git push` target to deploy code.

```
Usage:

./main.sh init
./main.sh pull [--repo GHOST_REPO] [--name GHOST_DEPLOY_NAME] [--commit commit_sha1]
./main.sh remote <ssh-options> -- [exec] <command>
```

Example Tasks:
- Install essentials
- Install Golang
- Install nvm + npm + node
- Install MongoDB and configures systemd services
- Setup SSH config
- Setup git bare repo

Each task is a bash function in the `init` file.