### Ghost

Scripts for friction-free manual production environment preparation, build and deployment.

Designed with early-stage companies and small teams in mind, who are not yet ready for containers.

- Brings Ubuntu-based machines from bare to full production environment with a simple one line init.
- Transfers and updates itself on each `remote` run to the targets.
- Sets up bare git repo, and makes itself a `git push` target to deploy code.

```
Usage:

./main.sh init
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

The core repo init is intentionally minimal. It's not intended to be one large monolith script. It's recommended for the scripts to be forked or copied and, functions added/removed based on the particular projects.