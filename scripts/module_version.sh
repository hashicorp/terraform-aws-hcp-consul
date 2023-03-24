#!/bin/bash

old="0\.11\.0"
new=0.11.1

for platform in ec2 ecs eks; do
  file=examples/hcp-$platform-demo/main.tf
  sed -i.bak "s/~> $old/~> $new/" $file
  rm -rf $file.bak
done
