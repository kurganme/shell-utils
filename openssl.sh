set_var() {
    eval "$1='$(echo "$2" | sed "s|'|'\"'\"'|")'"
}

cert_shield_extract() {
    local name="$1" value="$2"
    value="-----BEGIN $name-----${value#*-----BEGIN $name-----}"
    echo "${value%-----END $name-----*}-----END $name-----"
}

cert_selfsigned_make() {
    local var_cer="$1" var_key="$2" subj="$3" res
    shift 3
    res="$(
        printf '%s\n' '[req]' 'distinguished_name=rdn' \
               'x509_extensions=ext' '[rdn]' '[ext]' "$@" |
        openssl req \
            -x509 -nodes -new -newkey rsa:2048 -sha1 \
            -days "${cert_days:-99999}" -config /dev/stdin \
            -subj "$subj" -keyout -)"
    set_var "$var_cer" "$(cert_shield_extract 'CERTIFICATE' "$res")"
    set_var "$var_key" "$(cert_shield_extract 'PRIVATE KEY' "$res")"
}

cert_make() {
    local var_cer="$1" var_key="$2" issuer_cer="$3" issuer_key="$4" \
          subj="$5" res req key cer serial
    shift 5
    res="$(
        openssl req -nodes -new -newkey rsa:2048 -sha256 \
                -subj "$subj" \
                -out /dev/stdout -keyout /dev/stdout )"
    key="$(cert_shield_extract 'PRIVATE KEY' "$res")"
    req="$(cert_shield_extract 'CERTIFICATE REQUEST' "$res")"
    serial="0x$(openssl rand -hex 16)"
    cer="$(
        printf '%s\n' "$@" | {
        echo "$issuer_cer" | { echo "$issuer_key" | { echo "$req" |
        openssl x509 -req -CA /dev/fd/4 -CAkey /dev/fd/5 -in /dev/fd/6 \
                -set_serial "$serial" -extfile /dev/fd/3 \
                -days "${cert_days:-99999}" -sha256 2>/dev/null \
                6<&0; } 5<&0; } 4<&0; } 3<&0)"
    set_var "$var_cer" "$cer"
    set_var "$var_key" "$key"
}
