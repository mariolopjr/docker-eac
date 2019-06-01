#!/bin/bash
set -euo pipefail

# customization BEGIN
DRIVECFG=./drives.txt
DCFG=./eac.yml
WDIR=$HOME/wine
SHARE=/scratch/CD
SCREEN_WIDTH=1920
SCREEN_HEIGHT=1080
# customization END

function gen_header() {
cat <<EOD
---
version: '2'
services:

EOD
}

function gen_drive() {
cat <<EOD
# $driveid
  $drivename:
    image: "attilabogar/docker-eac:latest"
    ports:
      - $vnc:5999
    environment:
      - NODE=$drivename
      - SCREEN_WIDTH=$SCREEN_WIDTH
      - SCREEN_HEIGHT=$SCREEN_HEIGHT
      - UID=$(id -u)
      - GID=$(id -g)
    devices:
      - "$sr:/dev/sr0:rwm"
    volumes:
     - $SHARE:/data
     - $WDIR/$drivename:/srv/wine

EOD
}

if ! [ -s "$DRIVECFG" ]
then
  echo "No $DRIVECFG found!"
  exit 2
fi

# tear down old stack if present
if [ -s "$DCFG" ]
then
  docker-compose -f "$DCFG" -p eac down || :
fi

port=11
gen_header > "$DCFG"
vnctmp=$(mktemp)
declare -i i=0
while read -r drivename driveid
do
  # check if drive exists
  if [ -h "/dev/disk/by-id/$driveid" ]
  then
    i=$[i+1]
    sr=$(readlink -f "/dev/disk/by-id/$driveid")
    echo "$(hostname --fqdn):$port $drivename" >> $vnctmp
    vnc=$[5900+port]
    gen_drive >> "$DCFG"
    port=$[port+1]
    mkdir -p "$WDIR/$drivename"
  fi
done < "$DRIVECFG"

if [[ $i -gt 0 ]]
then
  docker-compose -f "$DCFG" -p eac up -d
  echo ""
  echo "VNC screens:"
  cat "$vnctmp"
  rm -f "$vnctmp"
  echo ""
  echo "Press ENTER to drop the stack..."
  read enter
  docker-compose -f "$DCFG" -p eac down && rm -f "$DCFG"
else
  rm -f "$DCFG"
  echo "No CD-ROM drives found!"
fi

echo "GOOD BYE!"
