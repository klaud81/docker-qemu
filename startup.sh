#!/bin/bash
sleep 2 
set -e

[ -n "$DEBUG" ] && set -x
# Create the kvm node (required --privileged)
if [ ! -e /dev/kvm ]; then
   set +e
   mknod /dev/kvm c 10 $(grep '\<kvm\>' /proc/misc | cut -f 1 -d' ')   
   set -e
fi

# mountpoint check
if [ ! -d /data ]; then
    if [ "${ISO:0:1}" != "/" ] || [ -z "$VM_DISK_IMAGE" ]; then
        # echo "/data not mounted: using -v to mount it"
        exit 1
    fi
fi
VM_RAM=${VM_RAM:-2048}
VM_CPU=${VM_CPU:-1}
VM_DISK_IMAGE_SIZE=${VM_DISK_IMAGE_SIZE:-10G}
SPICE_PORT=5900


if [ -n "$ISO" ]; then
    # echo "[iso]"
    if [ "${ISO:0:1}" != "/" ]; then
        basename=$(basename $ISO)
        if [ ! -f "/data/${basename}" ] || [ "$ISO_FORCE_DOWNLOAD" != "0" ]; then
            wget -O- "$ISO" > /data/${basename}
        fi
        ISO=/data/${basename}
    fi
    FLAGS_ISO="-cdrom $ISO"
    if [ ! -f "$ISO" ]; then
        # echo "ISO fild not found: $ISO"
        exit 1
    fi
fi

echo "[disk image]"
if [ -z "${VM_DISK_IMAGE}" ] || [ "$VM_DISK_IMAGE_CREATE_IF_NOT_EXIST" != "0" ]; then
    FLAGS_DISK_IMAGE=${VM_DISK_IMAGE:-/data/disk-image}
    if [ ! -f "$VM_DISK_IMAGE" ]; then
        qemu-img create -f qcow2 ${FLAGS_DISK_IMAGE} ${VM_DISK_IMAGE_SIZE}
    fi
fi
# [ -f "$FLAGS_DISK_IMAGE" ] || { echo "VM_DISK_IMAGE not found: ${FLAGS_DISK_IMAGE}"; exit 1; }
echo "parameter: ${FLAGS_DISK_IMAGE}"

echo "[network]"
# If we have a NETWORK_BRIDGE_IF set, add it to /etc/qemu/bridge.conf
if [ -z "$NETWORK" ] || [ "$NETWORK" == "bridge" ]; then
    echo "allow br0" >/etc/qemu/bridge.conf
    ipaddr_cidr=$(ip a s eth0|awk '$1 == "inet" {print $2}')
    ipaddr=${ipaddr_cidr%/*}
    defaultgw=$(ip r | awk '$1 == "default" {print $3}')
    dhcp_prefix=${ipaddr_cidr%.*}
    brctl addbr br0
    brctl addif br0 eth0
    ip addr del ${ipaddr_cidr} dev eth0
    ip addr replace ${ipaddr_cidr} dev br0
    ip link set br0 up
    ip route add default via ${defaultgw} dev br0
    FLAGS_NETWORK="-netdev bridge,br=br0,id=net0 -device virtio-net,netdev=net0"
    dnsmasq --dhcp-range ${dhcp_prefix}.2,${dhcp_prefix}.254
elif [ "$NETWORK" == "tap" ]; then
    echo "allow $NETWORK_BRIDGE_IF" >/etc/qemu/bridge.conf

    # Make sure we have the tun device node
    if [ ! -e /dev/net/tun ]; then
       set +e
       mkdir -p /dev/net
       mknod /dev/net/tun c 10 $(grep '\<tun\>' /proc/misc | cut -f 1 -d' ')
       set -e
    fi

    FLAGS_NETWORK="-netdev bridge,br=${NETWORK_BRIDGE_IF},id=net0 -device virtio-net,netdev=net0"
else
    FLAGS_NETWORK="-netdev tap,id=net0,script=/var/qemu-ifup -device virtio-net,netdev=net0"
    FLAGS_NETWORK=""
fi
echo "Using ${NETWORK}"
echo "parameter: ${FLAGS_NETWORK}"

echo "[Remote Access]"
if [ -z "$REMOTE_ACCESS" ] || [ "$REMOTE_ACCESS" == "spice" ]; then
    FLAGS_REMOTE_ACCESS="-vga qxl -spice port=${SPICE_PORT},addr=0.0.0.0,disable-ticketing"
elif [ "$REMOTE_ACCESS" == "vnc" ]; then
####  Require that password based authentication is used for client connections ####
#-vnc 0.0.0.0:1,password -k en-us
    FLAGS_REMOTE_ACCESS="-vnc :0"

    if [ ! -z "${PASSWORD}" ]; then
	echo "password: $PASSWORD"    
        FLAGS_REMOTE_ACCESS="-vnc :0,password -monitor stdio "
    fi
fi
echo "parameter: ${FLAGS_REMOTE_ACCESS}"



# Execute with default settings

set -x


#TYPE=qemu64
#TYPE="EPYC,+ibpb"
TYPE="host"
#{VM_CPU}

/root/noVNC/utils/launch.sh --listen 6080 --web /root/noVNC/build/ &

if [ -z "${PASSWORD}" ]; then
    exec /usr/bin/qemu-system-x86_64 ${FLAGS_REMOTE_ACCESS} \
   -k en-us -m ${VM_RAM} -cpu ${TYPE} -smp sockets=1,cores=${VM_CPU},threads=1 \
   -vga virtio \
   -enable-kvm \
   -usbdevice tablet \
   ${FLAGS_NETWORK} \
   ${FLAGS_ISO} \
   ${FLAGS_DISK_IMAGE}
else
    echo "====== password set ${PASSWORD}dPcks1234d ============"
    exec echo -e "change vnc password\n${PASSWORD}\ncont\n" | /usr/bin/qemu-system-x86_64 ${FLAGS_REMOTE_ACCESS} \
   -k en-us -m ${VM_RAM} -cpu ${TYPE} -smp sockets=1,cores=${VM_CPU},threads=1 \
   -vga virtio \
   -enable-kvm \
   -usbdevice tablet \
   ${FLAGS_NETWORK} \
   ${FLAGS_ISO} \
   ${FLAGS_DISK_IMAGE}
fi

#    -enable-vnc \
#    -enable-vnc-png \
