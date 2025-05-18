#!/usr/bin/env bash
set -euo pipefail

# deploy.sh - remote deploy script for HalibutCoin
# Requires env: SSH_KEY, DEPLOY_HOST, DEPLOY_USER

# write SSH key
mkdir -p ~/.ssh
echo "$SSH_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# add host key
ssh-keyscan -H "$DEPLOY_HOST" >> ~/.ssh/known_hosts

# remote commands
essh "$DEPLOY_USER@$DEPLOY_HOST" << 'EOF'
# ensure repo
if [ ! -d ~/halibutcoin ]; then
  git clone https://github.com/${GITHUB_REPOSITORY}.git ~/halibutcoin
fi
cd ~/halibutcoin
# fetch latest code
git fetch origin master
git reset --hard origin/master

# install deps
sudo apt-get update
sudo apt-get install -y build-essential autoconf automake libtool pkg-config \
  libssl-dev libevent-dev libboost-system-dev libboost-filesystem-dev \
  libboost-chrono-dev libboost-test-dev libboost-thread-dev libzmq3-dev libfmt-dev dos2unix

# build
dos2unix autogen.sh && chmod +x autogen.sh
./autogen.sh
./configure --disable-wallet --enable-debug --with-miniupnpc=no
make -j$(nproc)

# restart service
sudo systemctl restart halibutcoind || true
EOF
