FROM ubuntu:20.04
LABEL authors="Mario Lopez <mariolopjr@gmail.com>"

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

# useful packages
RUN apt-get -qqy update \
  && apt-get -y dist-upgrade \
  && apt-get -qqy --no-install-recommends install \
    bzip2 \
    ca-certificates \
    tzdata \
    sudo \
    wget \
    gnupg \
    tzdata \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# timezone 
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

RUN dpkg --add-architecture i386

# EAC requirement
RUN mkdir /cdrom && echo '/dev/sr0 /cdrom iso9660 noauto 0 0' >> /etc/fstab

# set up X over VNC
RUN apt-get update -qqy \
  && apt-get -qqy install \
    locales \
    xvfb x11vnc \
    openbox obconf lxterminal tint2 menu \
    eject \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#
### WineHQ
#
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key \
  && apt-key add winehq.key \
  && apt-get -qqy update \
  && apt-get -qqy install \
    software-properties-common \
    apt-transport-https \
  && apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' \
  && apt-get -qqy update \
  && apt-get --install-recommends -y install \
    winehq-stable \
  && rm -rf winehq.key /var/lib/apt/lists/* /var/cache/apt/*

#
# setup openbox
#
COPY openbox/autostart openbox/menu.xml \
  /etc/xdg/openbox/
COPY tint2/tint2rc.custom /etc/xdg/tint2/

# entry point
COPY entrypoint.sh /
COPY session.sh /

CMD ["/entrypoint.sh"]
