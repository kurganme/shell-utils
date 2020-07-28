#!/bin/sh
set -ueo pipefail

. "$(dirname "$(readlink -f "$0")")"/openssl.sh

cert_days=365 # defaults to 99999

cert_selfsigned_make \
    ca_cert ca_privkey \
    '/C=US/O=DigiCert Inc/OU=www.digicert.com/CN=DigiCert Global Root CA' \
    'keyUsage=critical,digitalSignature,keyCertSign,cRLSign' \
    'basicConstraints=critical,CA:true' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid,issuer'

echo "$ca_cert" > ca_cert.pem
echo "$ca_privkey" > ca_privkey.pem

cert_make \
    intm_cert intm_privkey \
    "$ca_cert" "$ca_privkey" \
    '/C=US/O=DigiCert Inc/CN=DigiCert SHA2 Secure Server CA' \
    'basicConstraints=critical,CA:true,pathlen:0' \
    'keyUsage=critical,digitalSignature,keyCertSign,cRLSign' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid,issuer'

echo "$intm_cert" > intm_cert.pem
echo "$intm_privkey" > intm_privkey.pem

cert_make \
    web_cert web_privkey \
    "$intm_cert" "$intm_privkey" \
    '/C=US/ST=Pennsylvania/L=Paoli/O=Duck Duck Go\, Inc./CN=*.duckduckgo.com' \
    'authorityKeyIdentifier=keyid,issuer' \
    'subjectKeyIdentifier=hash' \
    'subjectAltName=DNS:*.duckduckgo.com, DNS:duckduckgo.com' \
    'keyUsage=critical,digitalSignature,keyEncipherment' \
    'extendedKeyUsage=serverAuth,clientAuth' \
    'basicConstraints=critical,CA:false'

echo "$web_cert" > web_cert.pem
echo "$web_privkey" > web_privkey.pem
