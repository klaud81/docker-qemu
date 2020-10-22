FROM alpine

ENV HOME /root
ENV	DEBIAN_FRONTEND noninteractive 
ENV	LANG en_US.UTF-8 
ENV	LANGUAGE en_US.UTF-8 
ENV	LC_ALL C.UTF-8 
ENV	REMOTE_HOST localhost 
ENV	REMOTE_PORT 5900

ENV VM_RAM=2048
ENV VM_DISK_IMAGE_SIZE=30G
ENV VM_DISK_IMAGE=/data/diskImage
ENV VM_DISK_IMAGE_CREATE_IF_NOT_EXIST=1
ENV ISO=http://releases.ubuntu.com/14.04.2/ubuntu-14.04.2-desktop-amd64.iso
ENV ISO_FORCE_DOWNLOAD=0
ENV NETWORK=
ENV REMOTE_ACCESS=vnc
ENV PASSWORD=


#RUN echo -e "http://nl.alpinelinux.org/alpine/v3.5/main\nhttp://nl.alpinelinux.org/alpine/v3.5/community" > /etc/apk/repositories
#RUN sed -i 's/dl-cdn/nl/' /etc/apk/repositories
#RUN apk --update

#ADD /apk /apk
#RUN cp apk/.abuild/-58b83ac3.rsa.pub /etc/apk/keys
#RUN apk --no-cache --update add ./apk/x11vnc-0.9.13-r0.apk


RUN apk update && apk add \
      nodejs-npm \
      nodejs \
      bash \
      fluxbox \
      git \
      supervisor \
      xvfb \
      x11vnc \
      python2 \
      libvirt-daemon \
      qemu-img \
      qemu-system-x86_64 \
      qemu \
      wget \
      bridge-utils \
      dnsmasq \
      nano \ 
--update-cache \
        --repository https://alpine.global.ssl.fastly.net/alpine/edge/community \
        --repository https://alpine.global.ssl.fastly.net/alpine/edge/main \
        --repository https://dl-3.alpinelinux.org/alpine/edge/testing 

RUN git clone https://github.com/novnc/noVNC.git /root/noVNC \
	&& git clone https://github.com/novnc/websockify /root/noVNC/utils/websockify \
	&& rm -rf /root/noVNC/.git \
	&& rm -rf /root/noVNC/utils/websockify/.git \
	&& cd /root/noVNC \
	&& npm install npm@latest \
	&& npm install \
	&& ./utils/use_require.js --as commonjs --with-app \
	&& cp /root/noVNC/node_modules/requirejs/require.js /root/noVNC/build \
    && ln -s /root/noVNC/build/vnc.html /root/noVNC/build/index.html \
	&& sed -i -- "s/ps -p/ps -o pid | grep/g" /root/noVNC/utils/launch.sh \
	&& apk del git nodejs-npm nodejs


EXPOSE 5900
EXPOSE 6080

VOLUME /data

ADD startup.sh /

ENTRYPOINT ["/startup.sh"]
