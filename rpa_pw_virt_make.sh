#!/bin/bash
sleep 2 
set -e
set -x

if [ $# -ne 1 ]; then
 echo "Usage: $0 [num]"
 exit -1
else
 echo "ok"
fi

echo $1

PORT_1=6080
PORT_2=5900
EXT_PORT_1=$(($PORT_1 + $1))
EXT_PORT_2=$(($PORT_2 + $1))
# 3, 4
CPU=4
# 8092, 10240
MEM=8092
# password == null is no passwd, 
PASSWORD=password

# NETWORK brige, tap , other
#  -e NETWORK=tap \
docker run -d --privileged --cpus=$CPU \
  --name win10img-$1 \
  -v ${PWD}:/data \
  -e VM_DISK_IMAGE=/data/images/win10img-$1 \
  -e VM_DISK_IMAGE_SIZE=60G \
  -e VM_RAM=$MEM \
  -e ISO=virtio-win-0.1.187.iso \
  -e PASSWORD=${PASSWORD} \
  -p $EXT_PORT_1:$PORT_1 \
  -p $EXT_PORT_2:$PORT_2 \
  registry-airi.local/airihq/klaud81/qemunovnc:dev-rpa

