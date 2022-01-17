#!/bin/bash

file () {
  echo "examples/hcp-$1-demo/main.tf"
}

dev () {
  platform=$1
  perl -i -pe "BEGIN{undef \$/;} s/hashicorp\/hcp-consul\/aws\/\/modules\/hcp-$platform-client\"\r?\n  /..\/..\/modules\/hcp-$platform-client\"\n  # /smg" $(file $1)
  perl -i -pe "BEGIN{undef \$/;} s/hashicorp\/hcp-consul\/aws\/\/modules\/k8s-demo-app\"\r?\n  /..\/..\/modules\/k8s-demo-app\"\n  # /smg" $(file $1)
  perl -i -pe "BEGIN{undef \$/;} s/hashicorp\/hcp-consul\/aws\"\r?\n  /..\/..\"\n  # /smg" $(file $1)
}

prod () {
  platform=$1
  perl -i -pe "s/# version/version/smg" $(file $1)
  perl -i -pe "s/\.\.\/\.\.\/modules\/hcp-$platform-client/hashicorp\/hcp-consul\/aws\/\/modules\/hcp-$platform-client/smg" $(file $1)
  perl -i -pe "s/\.\.\/\.\.\/modules\/k8s-demo-app/hashicorp\/hcp-consul\/aws\/\/modules\/k8s-demo-app/smg" $(file $1)
  perl -i -pe "s/\.\.\/\.\./hashicorp\/hcp-consul\/aws/smg" $(file $1)
}

isDev () {
  grep -q "# version" $(file $1)
  echo $?
}

dev=$(isDev "ec2")
for platform in ec2 ecs eks; do
  if [ $dev -eq 0 ]; then
    prod $platform
  else
    dev $platform
  fi
done
