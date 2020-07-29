#!/bin/sh
set -ueo pipefail

sd="$(dirname "$(readlink -f "$0")")"
name=duckduckgo

. "$sd"/../openssl-utils.sh

cert_days=365 # defaults to 99999

cert_selfsigned_make \
    root_cert root_privkey \
    '/C=US/O=DigiCert Inc/OU=www.digicert.com/CN=DigiCert Global Root CA' \
    'keyUsage=critical,digitalSignature,keyCertSign,cRLSign' \
    'basicConstraints=critical,CA:true' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid,issuer'

echo "$root_cert" > "$name"-like-root_cert.pem
echo "$root_privkey" > "$name"-like-root_privkey.pem

cert_make \
    intm_cert intm_privkey \
    "$root_cert" "$root_privkey" \
    '/C=US/O=DigiCert Inc/CN=DigiCert SHA2 Secure Server CA' \
    'basicConstraints=critical,CA:true,pathlen:0' \
    'keyUsage=critical,digitalSignature,keyCertSign,cRLSign' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid,issuer'

echo "$intm_cert" > "$name"-like-intm_cert.pem
echo "$intm_privkey" > "$name"-like-intm_privkey.pem

cert_make \
    leaf_cert leaf_privkey \
    "$intm_cert" "$intm_privkey" \
    '/C=US/ST=Pennsylvania/L=Paoli/O=Duck Duck Go\, Inc./CN=*.duckduckgo.com' \
    'authorityKeyIdentifier=keyid,issuer' \
    'subjectKeyIdentifier=hash' \
    'subjectAltName=DNS:*.duckduckgo.com, DNS:duckduckgo.com' \
    'keyUsage=critical,digitalSignature,keyEncipherment' \
    'extendedKeyUsage=serverAuth,clientAuth' \
    'basicConstraints=critical,CA:false'

echo "$leaf_cert" > "$name"-like-leaf_cert.pem
echo "$leaf_privkey" > "$name"-like-leaf_privkey.pem

cert_dump() {
    openssl x509 -text -noout -nameopt RFC2253 -certopt no_pubkey,no_sigdump \
            "$@"
}

cert_diff() {
    cert_dump -in "$1" | { cert_dump -in "$2" | diff -y - /dev/fd/3; } 3<&0
}

for i in root intm leaf; do
    cert_diff "$sd"/"$name"-like-"$i"_cert.pem \
              "$sd"/"$name"-"$i"_cert.pem || true
done
