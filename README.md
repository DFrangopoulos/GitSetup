# TODO
THIS PROJECT IS IN PROGRESS RUNNING IT COULD HARM YOUR COMPUTER.
- Add systemd services

# Description
Setup a Git Server using two lighttpd instances. 
- One instance runs http and hosts gitweb for public viewing of repositories (on port 3000).
- The other instance runs https and is used for secure authenticated commits to the repo with git-http-backed (on port 4000).

# Installation
This should ideally be installed in a base Debian 10 virtual machine. To install and configure run:
```bash
bash Git_VM_Setup.sh
```




