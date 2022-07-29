#!/bin/bash

generate_base_terraform () {
  cat examples/hcp-$1-demo/{providers,main,output}.tf \
    | sed -e '/provider_meta/,+2d' \
    | sed -e 's/var/local/g' \
    | sed -e 's/local\.tier/"development"/g' \
    | sed -e 's/local\.hvn_cidr_block/"172.25.32.0\/20"/g'
}

generate_base_existing_vpc_terraform () {
  generate_base_terraform $1 \
    | sed -e 's/module\.vpc\.vpc_id/local\.vpc_id/' \
    | sed -e 's/module\.vpc\.public_subnets\[0\]/local\.public_subnet1/' \
    | sed -e 's/module\.vpc\.public_route_table_ids/\[local\.public_route_table_id\]/' \
    | sed -e 's/module\.vpc\.private_route_table_ids/\[local\.private_route_table_id\]/'
}

generate_existing_vpc_terraform () {
  case $1 in
    ec2)
      generate_base_existing_vpc_terraform $1 \
        | sed -e '/aws_availability_zones/,+17d' \
        | sed -e 's/module\.vpc\.public_subnets/\[local\.public_subnet1\]/'
      ;;
    *)
      generate_base_existing_vpc_terraform $1 \
        | sed -e '/aws_availability_zones/,+20d' \
        | sed -e 's/module\.vpc\.private_subnets/\[local\.private_subnet1, local\.private_subnet2\]/' \
        | sed -e 's/module\.vpc\.public_subnets/\[local\.public_subnet1, local\.public_subnet2\]/'
      ;;
  esac
}

generate_locals () {
  echo "locals {"
  cat scripts/locals.snip
  cat scripts/$1.snip
  echo "}"
  echo ""
}

generate_existing_vpc_locals () {
  echo "locals {"
  cat scripts/locals.snip 
  cat scripts/$1_existing_vpc_locals.snip
  cat scripts/$1.snip
  echo "}"
  echo ""
}

generate () {
  file=hcp-ui-templates/$1/main.tf
  mkdir -p $(dirname $file)
  generate_locals $1> $file
  generate_base_terraform $1 >> $file

  file=hcp-ui-templates/$1-existing-vpc/main.tf
  mkdir -p $(dirname $file)
  generate_existing_vpc_locals $1 > $file
  generate_existing_vpc_terraform $1 >> $file
}

for platform in ec2 eks ecs; do
  generate $platform
done

source ./scripts/terraform_fmt.sh

cd test/hcp
go test -update .
cd -
