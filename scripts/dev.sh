#!/bin/bash

dev () {
  platform=$1
  file="examples/hcp-$1-demo/main.tf"
  perl -i -pe "BEGIN{undef \$/;} s/hashicorp\/hcp-consul\/aws\/\/modules\/hcp-$platform-client\"\r?\n  /..\/..\/modules\/hcp-$platform-client\"\n  # /smg" $file
  perl -i -pe "BEGIN{undef \$/;} s/hashicorp\/hcp-consul\/aws\"\r?\n  /..\/..\/..\/terraform-aws-hcp-consul\"\n  # /smg" $file
}

for platform in ec2 ecs eks; do
  dev $platform
done
