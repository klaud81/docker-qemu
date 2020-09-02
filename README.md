# QEMU/KVM on Docker

Fork from [ulexus/qemu](https://github.com/Ulexus/docker-qemu)

## Usage

qemu + kvm + novnc 를 활용한 web 가상 데스크탑 
windows , linux 등을 설치 할수 있으며 속도도 나쁘지 않습니다.  
vnc 자체에 한계로 인해 프레임 드랍 현상이 있습니다. 게임은 가능하지만 원활하다고 하기엔 힘들어요. 
example 폴더에 kubernetes yaml 도 같이 올려 놓았습니다.


web virtual desktop with qemu + kvm + novnc
You can install windows, linux, etc. and the speed is also fast.
There is a frame drop due to limitations in vnc itself.
I have also put kubernetes yaml in the example folder.

Boot with ISO
```
docker run -d --privileged --cpus=2 \
    -v ${PWD}:/data \
    -e VM_DISK_IMAGE=/data/win10img \ 
    -e VM_DISK_IMAGE_SIZE=50G \
    -e VM_RAM=4096 \
    -e ISO=wind10.iso \
    -p 6080:6080 \
    -p 5900:5900 \
    khjde1207/qemunovnc
```

install windows-guest
download url : https://www.spice-space.org/download/binaries/spice-guest-tools/
```
docker run -d --privileged --cpus=2 \
    -v ${PWD}:/data \
    -e VM_DISK_IMAGE=/data/win10img \ 
    -e VM_DISK_IMAGE_SIZE=50G \
    -e VM_RAM=4096 \
    -e ISO=windows-guest.iso \
    -p 6080:6080 \
    -p 5900:5900 \
    khjde1207/qemunovnc
```

Turn on machine with last image
```
docker run --privileged -v ${PWD}:/data \
    -e VM_DISK_IMAGE=/data/disk-image \
    -e ISO= \
    -p 16080:6080 \
    -p 15900:5900 \
    dorowu/qemu-iso
```

```
docker run -d --privileged --cpus=2 \
    -v ${PWD}:/data \
    -e VM_DISK_IMAGE=/data/win10img \
    -e VM_DISK_IMAGE_SIZE=50G \
    -e VM_RAM=4096 \
    -e ISO= \
    -p 6080:6080 \
    -p 5900:5900 \
    khjde1207/qemunovnc
```


Then browse http://127.0.0.1:6080/
