
users_reset() {
    # works with alpine:3.12
    local user_regex="${1:-root}" group_regex="${2:-root|shadow|tty}"
    sed -Eni '/^('"$user_regex"'):/p' /etc/passwd /etc/shadow
    sed -Eni '/^('"$group_regex"'):/p' \
        /etc/group $([ -e /etc/gshadow ] && echo /etc/gshadow)
    if [ -e /etc/default/useradd ]; then
        sed -Ei 's/^(GROUP=)/#\1/' /etc/default/useradd
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
