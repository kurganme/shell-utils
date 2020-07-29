#!/bin/sh
set -ueo pipefail

sd="$(dirname "$(readlink -f "$0")")"

. "$sd"/../openssl.sh

cert_days=365 # defaults to 99999

cert_selfsigned_make \
    root_cert root_privkey \
    '/O=Digital Signature Trust Co./CN=DST Root CA X3' \
    'basicConstraints=critical,CA:true' \
    'keyUsage=critical,keyCertSign,cRLSign' \
    'subjectKeyIdentifier=hash'

echo "$root_cert" > letsencrypt-like-root_cert.pem
echo "$root_privkey" > letsencrypt-like-root_privkey.pem

cert_make \
    intm_cert intm_privkey \
    "$root_cert" "$root_privkey" \
    '/C=US/O=Let'"'"'s Encrypt/CN=Let'"'"'s Encrypt Authority X3' \
    'basicConstraints=critical,CA:true,pathlen:0' \
    'keyUsage=critical,digitalSignature,keyCertSign,cRLSign' \
    'authorityKeyIdentifier=keyid,issuer' \
    'subjectKeyIdentifier=hash'

echo "$intm_cert" > letsencrypt-like-intm_cert.pem
echo "$intm_privkey" > letsencrypt-like-intm_privkey.pem

cert_make \
    leaf_cert leaf_privkey \
    "$intm_cert" "$intm_privkey" \
    '/CN=www.test-site.com' \
    'keyUsage=critical,digitalSignature,keyEncipherment' \
    'extendedKeyUsage=serverAuth,clientAuth' \
    'basicConstraints=critical,CA:false' \
    'subjectKeyIdentifier=hash' \
    'authorityKeyIdentifier=keyid,issuer' \
    'subjectAltName=DNS:www.test-site.com, DNS:test-site.com'

echo "$leaf_cert" > letsencrypt-like-leaf_cert.pem
echo "$leaf_privkey" > letsencrypt-like-leaf_privkey.pem

cert_dump() {
    openssl x509 -text -noout -nameopt RFC2253 -certopt no_pubkey,no_sigdump \
            "$@"
}

cert_diff() {
    cert_dump -in "$1" | { cert_dump -in "$2" | diff -y - /dev/fd/3; } 3<&0
}

for i in root intm leaf; do
    cert_diff "$sd"/letsencrypt-like-"$i"_cert.pem \
              "$sd"/letsencrypt-"$i"_cert.pem || true
done
