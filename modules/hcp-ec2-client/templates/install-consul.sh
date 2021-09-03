#!/usr/bin/env bash
set -ex

# Dependencies added
sudo add-apt-repository universe -y
sudo apt update -yq
sudo apt install unzip jq -qy

# Consul Dependencies
curl --silent -o consul.zip https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_amd64.zip
unzip consul.zip
sudo chown root:root consul
sudo mv consul /usr/bin/

#  Create directories
sudo useradd --system --home /etc/consul.d --shell /bin/false consul
sudo mkdir --parents /etc/consul.d
sudo mkdir --parents /var/consul
sudo chown --recursive consul:consul /etc/consul.d
sudo chown --recursive consul:consul /var/consul

# Replace the relative path with the explicit path where consul will run
echo "$(jq '.ca_file = "/etc/consul.d/ca.pem"' client_config.json )" > client_config.json
sudo mv client_config.json /etc/consul.d
sudo mv client_acl.json /etc/consul.d
sudo mv ca.pem /etc/consul.d

# Create the systemd service and ensure that the service starts
sudo mv consul.service /usr/lib/systemd/system/
sudo systemctl enable  consul.service
sudo systemctl start consul.service
