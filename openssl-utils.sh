set_var() {
    eval "$1='$(echo "$2" | sed "s|'|'\"'\"'|")'"
}

cert_shield_extract() {
    local name="$1" value="$2"
    value="-----BEGIN $name-----${value#*-----BEGIN $name-----}"
    echo "${value%-----END $name-----*}-----END $name-----"
}

cert_selfsigned_make() {
    local var_cert="$1" var_privkey="$2" subj="$3" res
    shift 3
    res="$(
        printf '%s\n' '[req]' 'distinguished_name=rdn' \
               'x509_extensions=ext' '[rdn]' '[ext]' "$@" |
        openssl req \
            -x509 -nodes -new -newkey rsa:2048 -sha1 \
            -days "${cert_days:-99999}" -config /dev/stdin \
            -subj "$subj" -keyout -)"
    set_var "$var_cert" "$(cert_shield_extract 'CERTIFICATE' "$res")"
    set_var "$var_privkey" "$(cert_shield_extract 'PRIVATE KEY' "$res")"
}

cert_make() {
    local var_cert="$1" var_privkey="$2" issuer_cert="$3" \
          issuer_privkey="$4" subj="$5" res req privkey cert serial
    shift 5
    res="$(
        openssl req -nodes -new -newkey rsa:2048 -sha256 \
                -subj "$subj" \
                -out /dev/stdout -keyout /dev/stdout )"
    privkey="$(cert_shield_extract 'PRIVATE KEY' "$res")"
    req="$(cert_shield_extract 'CERTIFICATE REQUEST' "$res")"
    serial="0x$(openssl rand -hex 16)"
    cert="$(
        printf '%s\n' "$@" | {
        echo "$issuer_cert" | { echo "$issuer_privkey" | { echo "$req" |
        openssl x509 -req -CA /dev/fd/4 -CAkey /dev/fd/5 -in /dev/fd/6 \
                -set_serial "$serial" -extfile /dev/fd/3 \
                -days "${cert_days:-99999}" -sha256 2>/dev/null \
                6<&0; } 5<&0; } 4<&0; } 3<&0)"
    set_var "$var_cert" "$cert"
    set_var "$var_privkey" "$privkey"
}

letsencrypt_like_make() {
    local root_cert root_privkey intm_cert intm_privkey leaf_cert leaf_privkey
    root_cert='-----BEGIN CERTIFICATE-----
MIIDKDCCAhCgAwIBAgIUI9SAwAmr/ZR3hdjA0t9BcYptK/UwDQYJKoZIhvcNAQEF
BQAwKzESMBAGA1UECgwJQWNtZSBJbmMuMRUwEwYDVQQDDAxUZXN0IFJvb3QgQ0Ew
IBcNMjAwNzI5MTU0NjEyWhgPMjI5NDA1MTMxNTQ2MTJaMCsxEjAQBgNVBAoMCUFj
bWUgSW5jLjEVMBMGA1UEAwwMVGVzdCBSb290IENBMIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEA3gOUqw7XaSfcsKFYaz4Z5OfmLoOQfanJIojuzf/Zwqmu
/mkbSmzB7swMAM+fBgTbdwn1ReFMa9C+lkE+MXKlW6BobtuWRvnFrqcMx5HXpbNN
1XB0cLxhOY1cq9gH7W+8eAMwJeueMn8DWKL/pA27QEFD3cUF57bImfI6WJQl1MIz
qfXtxJ06r4YCKZ/+DcCgu7UeO4nl24AjFWmWQrH/w53HXq1KQ+tYkoC4I1mv7HXy
lZdg29R/gVm7W8ucAoclellswjZsy4zGD6FbCKJaIWmfvlQjAjH2/zg7vS7fbuU2
kdZ5sXYrbm+VKk0UFXNzwLoMaljAvYIbp8EajnxtWQIDAQABo0IwQDAPBgNVHRMB
Af8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUIiUSQm0OhgJ6L0OG
I0mK2m88mb8wDQYJKoZIhvcNAQEFBQADggEBAMOgLkGMYES2EoJZVXuVbATEG0Mn
saKN32kSOAvZCE44O04EcYz1hmqcX5DhfIlSdnPlwfPEeXLU4+mzn2vrtFnHMMrC
Yjj/60UtaCzAHVsnhyRkI9GT/fi9F73OGHauuvOjj+xQIWIXsY9ldBAjRzxbvaCV
dRLElapBvTplNaDwGGDk7OOWJzxBBKVA3hI4TTHw0LFsB74XlbDzH8xtVwJIXEc2
XMqLBuoiAKowxFk6R6m+M/6Hqm2P/Ill1yeG6xdYbC8niylNvlZNiivJq2ddZYCx
OQtxo27w8uInLnX1luDnAyALyqMk1onqzjzYD0k3VHqbbfj5J8mUzadHFi8=
-----END CERTIFICATE-----'
    root_privkey='-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDeA5SrDtdpJ9yw
oVhrPhnk5+Yug5B9qckiiO7N/9nCqa7+aRtKbMHuzAwAz58GBNt3CfVF4Uxr0L6W
QT4xcqVboGhu25ZG+cWupwzHkdels03VcHRwvGE5jVyr2Aftb7x4AzAl654yfwNY
ov+kDbtAQUPdxQXntsiZ8jpYlCXUwjOp9e3EnTqvhgIpn/4NwKC7tR47ieXbgCMV
aZZCsf/DncderUpD61iSgLgjWa/sdfKVl2Db1H+BWbtby5wChyV6WWzCNmzLjMYP
oVsIolohaZ++VCMCMfb/ODu9Lt9u5TaR1nmxditub5UqTRQVc3PAugxqWMC9ghun
wRqOfG1ZAgMBAAECggEBALpB+sn/64yXGrk8w3dFZGf8fcpsKh6jANFuXBqLGWAN
B3j9KR4pXBJBMZjElr9v98dInXOA7qJNQHfCSLEnY78ZNkQ7CTqGdehu0XPk0Sx8
30G/1JB4GoE0LZkl5pC2e0GcOxq1L8Vhdac5KIuz0XK4zn0RvECHwogVBgomUA7L
RiVk6tjawo33dbly2bafGvtrHpr/Dz0ygNr5yWUvJjFX1tZF0Sl6Wp/eH7Me+V3G
bmwAz0a9imBUKAv8wqAGb9EgWLkZo/Ts8QTyMk+UqykuMdZtd4FghZ1j4m2z7qeB
YU5aQ8cHLtfNjd9f8v+fFqAz44EoHITYIuuXRn8UuTkCgYEA+bxpwp/aDVp0ohXx
sWE7pU8jVuG/xTItc8JybpuilORJJ6Tda6R0LQ90twojZwoc1j76CURuOA1ifKRa
vi4xlLm1e56kGNMDuXWFCEkEEuaSMd07JXODxX/qU2JNEpSZfCEBdRSle21QtKfy
YRcxCEQuOeGS7Wo031LLERlauB8CgYEA45UpPDke3f1PaglhAz2nln8n79R/Rohe
V+nY15dzVvEuiVRhkemtGvtY0BU5K1CMg0XPTh0eN3IvSJ+/PnLSZ5qsjm7P3fSZ
+DpBUIO++D635yOZTX+FKNGbeoUvdjcXUznroJW5Y58i7eVOT/OIDg1Dg9eCOIs8
li+b827EC4cCgYBeHkcRhWMNY0jPiUukWQu8ml2sMbovXGDK3r53twoH6R005qpY
Fgt+q/OFxDlhbOs/R06+TV7omwrCBML6J7ih33dpFnmrrWMa8xJm8/WoFeOFDWZs
D+PafAHY2RRI614I7Pt6n4RaRvGClEUBmFbvUZrGT6Aq/7rba32CfTa2awKBgBON
2mgpRESwoiUrPyGnJ4If1M+fg3wM9YY6On5zrd5XhLcZ//Qojs4VsJDYcfwNxLT2
x5QfnlwHPJbR2v3Dod5zBMaMMOISRTR11OzVFRCBWw3KGj71aPyT3fcOAID4xNFK
1bsLgk1T/A1SuYLXGuaSLy3h03eGRyNkXdLxvnh7AoGBAOWETBJM/atR60EHEHV6
OBTeCy2wHdE6+8HdDdz688s4St1uW9JQdpwcZwdTEF8UQ+ulWlONj9bvMc6rhwIp
T2wUdsbY6qdsE0k7zXco+bV0bhGnSQLyiQzjSt+Ms7GZWB+5jNlRUOUgxGuURFmB
kHEjmQs5Qh/pM115hqiM5BS6
-----END PRIVATE KEY-----'
    cert_make \
        intm_cert intm_privkey \
        "$root_cert" "$root_privkey" \
        '/C=IT/O=Acme Inc./CN=Test Intermediate CA ('`
            `"$(openssl rand -hex 4)"')' \
        'basicConstraints=critical,CA:true,pathlen:0' \
        'keyUsage=critical,digitalSignature,keyCertSign,cRLSign' \
        'authorityKeyIdentifier=keyid,issuer' \
        'subjectKeyIdentifier=hash'
    cert_make \
        leaf_cert leaf_privkey \
        "$intm_cert" "$intm_privkey" \
        '/CN='"$1" \
        'keyUsage=critical,digitalSignature,keyEncipherment' \
        'extendedKeyUsage=serverAuth,clientAuth' \
        'basicConstraints=critical,CA:false' \
        'subjectKeyIdentifier=hash' \
        'authorityKeyIdentifier=keyid,issuer' \
        'subjectAltName='`
            `"$(for i in "$@"; do printf '%s' DNS:"$i",; done | head -c-1)"
    tmpdir="$(mktemp -d -t openssl-utils.XXXXXXXXXX)"
    chmod go= "$tmpdir"
    echo "$leaf_cert" >"$tmpdir"/cert.pem
    echo "$intm_cert" >"$tmpdir"/chain.pem
    printf '%s\n' "$leaf_cert" "$intm_cert" >"$tmpdir"/fullchain.pem
    echo "$leaf_privkey" >"$tmpdir"/privkey.pem
    chmod -R u=rwX,go= "$tmpdir"
    tar c -C "$tmpdir" .
    rm -rf "$tmpdir"
}
