#!/bin/bash

# Install Node.js 18.x
sudo mkdir -p /etc/apt/keyrings
sudo rm -f /etc/apt/keyrings/nodesource.gpg && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=18
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update -y
sudo apt-get install -y nodejs
npm config set registry https://skimdb.npmjs.com/registry


rm /usr/lib/node_modules/yarn -R
rm /usr/lib/node_modules/pm2 -R

sudo npm install -g yarn
sudo npm install -g pm2
