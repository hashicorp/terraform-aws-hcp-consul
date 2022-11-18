global:
  enabled: false
  name: consul
  datacenter: ${datacenter}
  image: "hashicorp/consul-enterprise:${consul_version}-ent"
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: ${cluster_id}-hcp
      secretKey: bootstrapToken
  tls:
    enabled: true

%{ if consul_client_agent ~}
    enableAutoEncrypt: true
    caCert:
      secretName: ${cluster_id}-hcp
      secretKey: caCert
  gossipEncryption:
    secretName: ${cluster_id}-hcp
    secretKey: gossipEncryptionKey

client:
  enabled: true
  join: ${consul_hosts}
  nodeMeta:
    terraform-module: "hcp-eks-client"

controller:
  enabled: true
%{ endif ~}

externalServers:
  enabled: true
  hosts: ${consul_hosts}
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: ${k8s_api_endpoint}

server:
  enabled: false

connectInject:
  transparentProxy:
    defaultEnabled: true
  enabled: true
  default: true
%{ if !consul_client_agent ~}
  consulNode:
    meta:
      terraform-module: "hcp-eks-client"
%{ endif ~}

ingressGateways:
  enabled: true
  gateways:
    - name: ingress-gateway
      service:
        type: LoadBalancer
        ports:
        - port: 8080
