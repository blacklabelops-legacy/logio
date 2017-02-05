#!/bin/bash -x

set -o errexit

if [ -n "${DELAYED_START}" ]; then
  sleep ${DELAYED_START}
fi

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
