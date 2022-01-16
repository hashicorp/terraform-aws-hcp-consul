#!/bin/bash

if [ ! -f examples/existing-vpc/output.json ]; then
  cd examples/existing-vpc/
  terraform init
  terraform apply -auto-approve
  terraform output -json > output.json
  cd -
fi

output () {
  jq -r $1 examples/existing-vpc/output.json
}

defaults () {
  file="hcp-ui-templates/$1/main.tf"
  sed -i.bak "s/{{ \.ClusterID }}/$1/" $file
  sed -i.bak "s/{{ \.VPCRegion }}/us-west-2/" $file
  sed -i.bak "s/{{ \.HVNRegion }}/us-west-2/" $file
  sed -i.bak "s/{{ \.PublicSubnet1 }}/$(output ".public_subnet1.value")/" $file
  sed -i.bak "s/{{ \.PublicSubnet2 }}/$(output ".public_subnet2.value")/" $file
  sed -i.bak "s/{{ \.PrivateSubnet1 }}/$(output ".private_subnet1.value")/" $file
  sed -i.bak "s/{{ \.PrivateSubnet2 }}/$(output ".private_subnet2.value")/" $file
  sed -i.bak "s/{{ \.PublicRouteTableID }}/$(output ".public_route_table_id.value[0]")/" $file
  sed -i.bak "s/{{ \.PrivateRouteTableID }}/$(output ".private_route_table_id.value[0]")/" $file
  sed -i.bak "s/{{ \.VPCID }}/$(output ".vpc_id.value")/" $file
  rm -rf $(dirname $file)/*.bak
}

for template in ec2 ec2-existing-vpc eks eks-existing-vpc ecs ecs-existing-vpc; do
  defaults $template
done

