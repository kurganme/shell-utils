
users_reset() {
    local shell="${1:-/bin/ash}"
    echo 'root:x:0:0:root:/root:'"$shell" >/etc/passwd
    echo 'root:!::0:::::' >/etc/shadow
    echo 'root:x:0:root' >/etc/group
    echo 'root:!::root' >/etc/gshadow
    chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow
    chmod u=rw,go=r /etc/passwd /etc/group
    chmod u=rw,g=r,o= /etc/shadow /etc/gshadow
    if [ -e /etc/default/useradd ]; then
        sed -i -E 's/^(GROUP=)/#\1/' /etc/default/useradd
    fi
}

user_add() {
    local uname="$1" uid="$2"
    local gname="${3:-"$uname"}" gid="${4:-"$uid"}" \
          home="${5:-/var/empty}" shell="${6:-/sbin/nologin}"
    if [ -e /usr/sbin/adduser ] && [ -e /usr/sbin/addgroup ]; then
        addgroup -g "$gid" -S "$gname" ||:
        adduser -h "$home" -g "$gname" -s "$shell" \
                -G "$gname" -S -D -H -u "$uid" "$uname" ||:
    else
        groupadd -g "$gid" -r "$gname" ||:
        useradd -d "$home" -c "$gname" -s "$shell" \
                -g "$gname" -r    -M -u "$uid" "$uname" ||:
    fi
}
