#!/bin/bash -xe

FQDN=$1
EMAIL=$2

NGINX_CFG=/etc/nginx/sites-enabled/vhosts.conf
LETS_ENCRYPT_LIVE="/etc/letsencrypt/live"
KEY="${LETS_ENCRYPT_LIVE}/${FQDN}/privkey.pem"
CRT="${LETS_ENCRYPT_LIVE}/${FQDN}/cert.pem"

# use test cert option when testing package
CERTBOT_ARGS=""
#CERTBOT_ARGS="-test-cert"

# change ningx server_name from _ to fqdn
sed -i 's/^\([ \t]\+server_name[ \t]\+\)_\([ \t]*;[ \t]*\)$/\1'$FQDN'\2/' \
  $NGINX_CFG

# setup nginx let's encrypt certificate, redirect http to https, and enable auto renewal
certbot --nginx --agree-tos --no-eff-email --redirect \
  -d $FQDN -m $EMAIL $CERTBOT_ARGS &> /dev/null

# display certificate fingerprint
openssl x509 -noout -fingerprint -sha256 -inform pem -in $CRT
