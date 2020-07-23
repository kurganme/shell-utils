#!/bin/sh
set -ueo pipefail

. "$(dirname "$(readlink -f "$0")")"/openssl.sh

cert_days=365 # defaults to 99999

cert_selfsigned_make \
    ca_cer ca_key \
    '/C=US/O=DigiCert Inc/OU=www.digicert.com/CN=DigiCert Global Root CA' \
    'keyUsage=critical,digitalSignature,keyCertSign,cRLSign' \
    'basicConstraints=critical,CA:true' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid,issuer'

echo "$ca_cer" > ca_cer.pem
echo "$ca_key" > ca_key.pem

cert_make \
    intm_cer intm_key \
    "$ca_cer" "$ca_key" \
    '/C=US/O=DigiCert Inc/CN=DigiCert SHA2 Secure Server CA' \
    'basicConstraints=critical,CA:true,pathlen:0' \
    'keyUsage=critical,digitalSignature,keyCertSign,cRLSign' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid,issuer'

echo "$intm_cer" > intm_cer.pem
echo "$intm_key" > intm_key.pem

cert_make \
    web_cer web_key \
    "$intm_cer" "$intm_key" \
    '/C=US/ST=Pennsylvania/L=Paoli/O=Duck Duck Go\, Inc./CN=*.duckduckgo.com' \
    'authorityKeyIdentifier=keyid,issuer' \
    'subjectKeyIdentifier=hash' \
    'subjectAltName=DNS:*.duckduckgo.com, DNS:duckduckgo.com' \
    'keyUsage=critical,digitalSignature,keyEncipherment' \
    'extendedKeyUsage=serverAuth,clientAuth' \
    'basicConstraints=critical,CA:false'

echo "$web_cer" > web_cer.pem
echo "$web_key" > web_key.pem
