global:
  enabled: false
  name: consul
  datacenter: ${datacenter}
  image: "hashicorp/consul-enterprise:1.10.3-ent"
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: ${cluster_id}-hcp
      secretKey: bootstrapToken
  tls:
    enabled: true
    enableAutoEncrypt: true
    caCert:
      secretName: ${cluster_id}-hcp
      secretKey: caCert
  gossipEncryption:
    secretName: ${cluster_id}-hcp
    secretKey: gossipEncryptionKey

externalServers:
  enabled: true
  hosts: ${consul_hosts}
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: ${k8s_api_endpoint}

server:
  enabled: false

client:
  enabled: true
  join: ${consul_hosts}
  nodeMeta:
    terraform-module: "hcp-eks-client"

connectInject:
  enabled: true

ui:
  enabled: true

controller:
  enabled: true

ingressGateways:
  enabled: true
  gateways:
    - name: ingress-gateway
      service:
        type: LoadBalancer
