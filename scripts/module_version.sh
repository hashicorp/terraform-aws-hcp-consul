#!/bin/bash

old="0\.4\.2"
new=0.5.0

for platform in ec2 ecs eks; do
  file=examples/hcp-$platform-demo/main.tf
  sed -i.bak "s/$old/$new/" $file
  rm -rf $file.bak
done
