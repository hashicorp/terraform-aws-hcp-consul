#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

set -ex

start_service () {
	mv $1.service /usr/lib/systemd/system/
	systemctl enable $1.service
	systemctl start $1.service
}

setup_deps () {
	add-apt-repository universe -y

	# Add HashiCorp repository
	curl -fSL --retry 3 https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
	# test repo for release candidate versions
	apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) test"
	curl -L --retry 3 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/getenvoy.list
	apt update -y

	# Install Consul, Nomad, Envoy, and Nginx
	# Note: apt is unable to find packages if '-rc*' is used. Hence trimming '-rc' from version which is present only in case
	# of candidate release versions.
	version=$(sed -r 's/-rc([0-9]*)//g'<<<${consul_version})
	consul_package="consul-enterprise="$${version:1}"*"
	apt install -y apt-transport-https gnupg2 curl lsb-release nomad $${consul_package} getenvoy-envoy unzip jq apache2-utils nginx

	# Install Docker
	curl -fSL --retry 3 https://get.docker.com -o get-docker.sh
	sh ./get-docker.sh
}

setup_networking() {
	curl -L --retry 3 -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz
	mkdir -p /opt/cni/bin
	tar -C /opt/cni/bin -xzf cni-plugins.tgz
}

setup_consul() {
	mkdir --parents /etc/consul.d /var/consul
	chown --recursive consul:consul /etc/consul.d
	chown --recursive consul:consul /var/consul
	
	echo "${consul_ca}" | base64 -d > /etc/consul.d/ca.pem
	echo "${consul_config}" | base64 -d > client.temp.0
	ip=`hostname -I | awk '{print $1}'`
	jq '.ca_file = "/etc/consul.d/ca.pem"' client.temp.0 > client.temp.1
	jq --arg token "${consul_acl_token}" '.acl += {"tokens":{"agent":"\($token)"}}' client.temp.1 > client.temp.2
	jq '.ports = {"grpc":8502}' client.temp.2 > client.temp.3
	jq --arg node_id "${node_id}" '.node_meta += {"node_id":"\($node_id)"}' client.temp.3 > client.temp.4
	jq '.bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"'${vpc_cidr}'\" | attr \"address\" }}"' client.temp.4 > /etc/consul.d/client.json
}

setup_nginx() {
	mkdir -p /etc/nginx/
	echo "${consul_acl_token}" | htpasswd -i -c /etc/nginx/.htaccess nomad
	echo "${nginx_conf}" | base64 -d > /etc/nginx/nginx.conf
	systemctl restart nginx
}

setup_dns_forwarding () {
	mkdir /etc/systemd/resolved.conf.d/

	cat << EOF | tee -a /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=127.0.0.1:8600
DNSSEC=false
Domains=~consul
EOF

	systemctl restart systemd-resolved
}

cd /home/ubuntu/

echo "${nomad_service}" | base64 -d > nomad.service

setup_networking
setup_deps

# Optionally start the demo app.
if ${install_demo_app}
then
	setup_nginx
	echo "${consul_service}" | base64 -d > consul.service
	start_service "nomad"
	sleep 10
fi

setup_consul
start_service "consul"
setup_dns_forwarding

echo "done"
