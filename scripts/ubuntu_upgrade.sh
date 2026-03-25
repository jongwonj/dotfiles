#!/usr/bin/env bash
# Ubuntu Safe Release Upgrade Script (Server Non-Interactive)
# Before using: make sure to backup important files

# lsb_release -a
# sudo vi /etc/update-manager/release-upgrades
# and change 'Prompt=lts' to 'Prompt=normal'
# do-release-upgrade -c
# Run with: chmod +x ubuntu_upgrade.sh && sudo ./ubuntu_upgrade.sh

# IMPORTANT: If running over SSH, consider using tmux or nohup
# Example with nohup: nohup ./ubuntu_upgrade.sh > upgrade.log 2>&1 &
# Example with tmux:
# tmux new -s upgrade
# sudo ./ubuntu_upgrade.sh
# (You can detach with Ctrl+b d and reattach later with tmux attach -t upgrade)

# set -e # Exit immediately if a command exits with a non-zero status

echo ""
echo "1. Checking current Ubuntu version"
lsb_release -a
uname -r
df -h

echo ""
echo "2. Updating package lists"
sudo apt update -y

echo ""
echo "3. Upgrading installed packages"
sudo apt full-upgrade -y

echo ""
echo "4. Removing unnecessary packages"
sudo apt autoremove -y
sudo apt clean

echo ""
echo "5. Starting release upgrade"
sudo do-release-upgrade

echo ""
echo "6. Post-upgrade verification"
lsb_release -a
sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove -y

echo ""
echo "Upgrade complete! Please reboot the system and check that all services are running properly."
