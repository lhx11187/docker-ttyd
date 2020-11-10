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

    if [ "$USER" = "" ]; then
        USER="root"
    fi

    if [ "$PASSWORD" = "" ]; then
        PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
        echo
        echo "*******************************************"
        echo "***** $USER password is \"$PASSWORD\" *********"
        echo "*******************************************"
        echo
    fi

    if [ "$USER" != "root" ]; then
        ROOT_PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1`
        echo "root:${ROOT_PASSWORD}" | chpasswd

        echo $USER | grep -q -w -e bin -e daemon -e adm -e lp -e sync -e shutdown \
                                -e halt -e mail -e operator -e games -e ftp -e nobody \
                                -e systemd-network -e dbus -e tcpdump -e nginx
        if [ $? -eq 0 ]; then
            echo "invalid user name: $USER"
            exit 1
        fi

        if [ "$USER_ID" != "" ]; then
            if [ $USER_ID -lt 1000 ]; then
                echo "invalid uid: $USER_ID"
                exit 1
            fi
        else
            USER_ID=1000
        fi

        cp /root/.bashrc /etc/skel
        cp /root/.vimrc /etc/skel
        cp /root/.screenrc /etc/skel

        if [ "$GROUP_ID" != "" ]; then
            if [ $GROUP_ID -lt 1000 ]; then
                echo "invalid gid: $GROUP_ID"
                exit 1
            fi
            groupadd -g $GROUP_ID $USER
            useradd $USER -u $USER_ID -g $GROUP_ID -d /home/$USER
        else
            useradd $USER -u $USER_ID -d /home/$USER
        fi

        echo "${USER}:${PASSWORD}" | chpasswd
        echo "user=$USER" >> /etc/supervisord.d/ttyd.ini
        echo "directory=/home/$USER" >> /etc/supervisord.d/ttyd.ini
        echo "environment=HOME=\"/home/$USER\"" >> /etc/supervisord.d/ttyd.ini

        if [ "$ENABLE_SUDO" = "true" ]; then
            echo "$USER	ALL=(ALL)	NOPASSWD: ALL" >> /etc/sudoers
        fi
    else
        echo "root:${PASSWORD}" | chpasswd
        echo "directory=/root" >> /etc/supervisord.d/ttyd.ini
    fi

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
