#!/bin/bash -x
set -o errexit

mkdir -p ~/.log.io

cat > ~/.log.io/web_server.conf <<_EOF_
exports.config = {
  host: '0.0.0.0',
  port: 28778,
_EOF_

if [ -n "${LOGIO_ADMIN_USER}" ] && [ -n "${LOGIO_ADMIN_PASSWORD}" ]; then
  cat >> ~/.log.io/web_server.conf <<_EOF_
  auth: {
    user: "${LOGIO_ADMIN_USER}",
    pass: "${LOGIO_ADMIN_PASSWORD}"
  },
_EOF_
fi

logio_dname=${LOGIO_CERTIFICATE_DNAME}

if [ -n "$LOGIO_CERTIFICATE_DNAME" ]; then
  if [ ! -f "/opt/server/keys/server.key" ]; then
    openssl req -subj "${logio_dname}" -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /opt/server/keys/server.key -out /opt/server/keys/server.crt
  fi
  cat >> ~/.log.io/web_server.conf <<_EOF_
  ssl: {
    key: '/opt/server/keys/server.key',
    cert: '/opt/server/keys/server.crt'
  },
_EOF_
fi

cat >> ~/.log.io/web_server.conf <<_EOF_
}
_EOF_
cat ~/.log.io/web_server.conf

cat > ~/.log.io/log_server.conf <<_EOF_
exports.config = {
  host: '0.0.0.0',
  port: 28777
}
_EOF_
cat ~/.log.io/log_server.conf

logio_nodename="node"

if [ -n "${LOGIO_HARVESTER_NODENAME}" ]; then
  logio_nodename=${LOGIO_HARVESTER_NODENAME}
fi

logio_streamname="stream"

if [ -n "${LOGIO_HARVESTER_STREAMNAME}" ]; then
  logio_streamname=${LOGIO_HARVESTER_STREAMNAME}
fi

harvester_log_files=""
LOG_FILES=""

if [ -n "${LOGIO_HARVESTER_LOGFILES}" ]; then
  harvester_log_files=${LOGIO_HARVESTER_LOGFILES}
fi

SAVEIFS=$IFS
IFS=' '
COUNTER=0
for logfile in $harvester_log_files
do
  if [ "$COUNTER" -eq "0" ]; then
    LOG_FILES=$LOG_FILES\"${logfile}\"
  else
    LOG_FILES=$LOG_FILES ,\"${logfile}\"
  fi
  let COUNTER=COUNTER+1
done
IFS=$SAVEIFS

cat > ~/.log.io/harvester.conf <<_EOF_
exports.config = {
  nodeName: "${logio_nodename}",
  logStreams: {
    ${logio_streamname}: [
      ${LOG_FILES}
    ]
  },
  server: {
    host: 'logio',
    port: 28777
  }
}
_EOF_
cat ~/.log.io/harvester.conf


if [ "$1" = 'logio' ]; then
  log.io-server
fi

if [ "$1" = 'harvester' ]; then
  log.io-harvester
fi

exec "$@"
