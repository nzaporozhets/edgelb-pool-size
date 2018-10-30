#!/bin/bash

if [ "$#" -ne 2 ];then
    echo "Usage: $0 <number of instances> <port range start>"
    echo "Example: $0 300 8000"
    echo "Requires DC/OS CLI installed and connected to the cluster. "
    exit 99
fi

load=$1
startport=$2
app=0
vm_count=$1

##### Spawning apps #####
for i in $(seq 0 $vm_count); do
#dcos marathon app add <<EOF
dcos marathon app add << EOF
{
  "id": "load-edge/testapp$i",
  "cmd": "echo \"testapp$i\" > index.html && python -m http.server 80",
  "container": {
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 0,
        "protocol": "tcp",
        "name": "port$i"
      }
    ],
    "type": "DOCKER",
    "volumes": [],
    "docker": {
      "image": "python:3",
      "forcePullImage": false,
      "privileged": false,
      "parameters": []
    }
  },
  "cpus": 0.01,
  "disk": 0,
  "instances": 1,
  "maxLaunchDelaySeconds": 3600,
  "mem": 32,
  "networks": [
    {
      "mode": "container/bridge"
    }
  ],
  "requirePorts": false,
  "upgradeStrategy": {
    "maximumOverCapacity": 1,
    "minimumHealthCapacity": 1
  }
}
EOF
#sleep 1
if [ $? -eq 0 ]; then
    echo "App $i started"
fi

done

##### Pool generation #####
#generating header
cat <<EOF >load-pool-$load.json
{
  "apiVersion": "V2",
  "name": "load-pool",
  "count": 1,
  "haproxy": {
    "frontends": [
EOF
#adding frontends
for i in $( seq $startport $(expr $startport + $load)); do
cat <<EOF >> load-pool-$load.json
      {
        "bindPort": $i,
        "protocol": "HTTP",
        "linkBackend": {
          "defaultBackend": "backend$app"
        }
      },
EOF
app=$(expr $app + 1 )

done

#adding backends header
cat <<EOF >> load-pool-$load.json
    ],
    "backends": [
EOF
app=0
#generating backends
for i in $( seq $startport $(expr $startport + $load)); do
cat <<EOF >>load-pool-$load.json
      {
        "name": "backend$app",
        "protocol": "HTTP",
        "services": [
          {
            "marathon": {
              "serviceID": "load-edge/testapp$app"
            },
            "endpoint": {
              "portName": "port$app"
            }
          }]
      },
EOF
app=$(expr $app + 1 )
done

#adding footer
cat << EOF >>load-pool-$load.json
    ]
  }
}
EOF

echo "EdgeLB pool is created and saved as $PWD/load-pool-$load.json "
