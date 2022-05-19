#!/usr/bin/env bash
set -ex

start_service () {
  mv $1.service /usr/lib/systemd/system/
  systemctl enable $1.service
  systemctl start $1.service
}

setup_deps () {
  add-apt-repository universe -y
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
  curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | gpg --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/getenvoy.list
  apt update -qy
	version="${consul_version}"
	consul_package="consul-enterprise="$${version:1}"*"
	apt install -qy apt-transport-https gnupg2 curl lsb-release nomad $${consul_package} getenvoy-envoy unzip jq apache2-utils nginx

	sudo apt install docker -y
	sudo apt install docker.io -y
}

setup_networking() {
	# echo 1 | tee /proc/sys/net/bridge/bridge-nf-call-arptables
	# echo 1 | tee /proc/sys/net/bridge/bridge-nf-call-ip6tables
	# echo 1 | tee /proc/sys/net/bridge/bridge-nf-call-iptables
	curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v1.0.0/cni-plugins-linux-$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)"-v1.0.0.tgz
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
	jq '.bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"'${vpc_cidr}'\" | attr \"address\" }}"' client.temp.3 > /etc/consul.d/client.json
}

setup_nginx() {
	mkdir -p /etc/nginx/
	echo "${consul_acl_token}" | htpasswd -i -c /etc/nginx/.htaccess nomad
	echo "${nginx_conf}" | base64 -d > /etc/nginx/nginx.conf
	systemctl restart nginx
}

cd /home/ubuntu/

echo "${consul_service}" | base64 -d > consul.service
echo "${nomad_service}" | base64 -d > nomad.service
echo "${hashicups}" | base64 -d > hashicups.nomad

setup_networking
setup_deps

setup_nginx
setup_consul

start_service "consul"
start_service "nomad"

# nomad and consul service is type simple and might not be up and running just yet.
sleep 10

nomad run hashicups.nomad

echo "done"
