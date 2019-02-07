#!/bin/bash -x

set -o errexit

mkdir -p ~/.log.io

if [ "$1" = 'logio' ]; then
  source /opt/logio/serversetup.sh
  log.io-server
elif [ "$1" = 'harvester' ]; then
  cd /opt/configGen
  node run_harvester.js
else
  exec "$@"
fi
