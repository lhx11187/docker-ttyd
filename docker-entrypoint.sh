#!/bin/bash

if [ "$1" != "" ]; then
    exec $@
fi

# pre hook
if [ "$PRE_HOOK" != "" ]; then
    echo "---- pre hook : $PRE_HOOK --------------"
    source $PRE_HOOK || exit 1
    echo "----------------------------------------"
fi

if [ ! -f /etc/init-done ]; then
    # pre hook (once)
    if [ "$PRE_HOOK_ONCE" != "" ]; then
        echo "---- pre hook once : $PRE_HOOK_ONCE ----"
        source $PRE_HOOK_ONCE || exit 1
        echo "----------------------------------------"
    fi

    if [ "$PASSWORD" = "" ]; then
        PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
        echo "generating root user password : \"$PASSWORD\""
    else
        echo "please use your specified password"
    fi
    echo "root:${PASSWORD}" | chpasswd

    # initializing nginx
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.org
    if [ "$NOSSL" = "true" ]; then
        sed "s/^#http/     /g" /etc/nginx/nginx.conf.tmpl > /etc/nginx/nginx.conf
    else
        sed "s/^#ssl/     /g" /etc/nginx/nginx.conf.tmpl > /etc/nginx/nginx.conf
        if [ ! -f /etc/pki/nginx/server.key ]; then
            openssl genrsa 2048 > /etc/pki/nginx/server.key
            openssl req -new -key /etc/pki/nginx/server.key <<EOF > /etc/pki/nginx/server.csr
JP
Default Prefecture
Default City
Default Company
Default Section
localhost



EOF
            openssl x509 -days 3650 -req -signkey /etc/pki/nginx/server.key < /etc/pki/nginx/server.csr > /etc/pki/nginx/server.crt
        fi
    fi
    sed -i "s/8080/$PORT/g" /etc/nginx/nginx.conf
    # initializing nginx done

    # post hook (once)
    if [ "$POST_HOOK_ONCE" != "" ]; then
        echo "---- post hook once : $POST_HOOK_ONCE ----"
        source $POST_HOOK_ONCE || exit 1
        echo "----------------------------------------"
    fi

    touch /etc/init-done
else
    echo "skip initializing"
fi

export TTYD_OPTS

# post hook
if [ "$POST_HOOK" != "" ]; then
    echo "---- post hook : $POST_HOOK ------------"
    source $POST_HOOK || exit 1
    echo "----------------------------------------"
fi

exec /usr/bin/supervisord
