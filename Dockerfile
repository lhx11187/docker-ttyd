FROM tmatsuo/centos:7

# Install packages
RUN yum install -y epel-release && \
    yum install -y supervisor nginx && \
    yum clean all

RUN curl -L -o /usr/local/bin/ttyd https://github.com/t-matsuo/ttyd/releases/download/1.6.1.1/ttyd_linux.x86_64 && \
    chmod 755 /usr/local/bin/ttyd

### Envrionment config
ENV HOME=/root \
    USER=root \
    PASSWORD=password \
    UID=0 \
    GID=0 \
    PORT=8080 \
    TTYD_OPTS="-p 10022 -P 30 -i lo /bin/bash"

### ADD and COPY files
COPY ./nginx/nginx-module-auth-pam-1.5.2-1.el7.x86_64.rpm /tmp/
COPY ./nginx/nginx.conf.tmpl /etc/nginx/
COPY ./nginx/default.d/* /etc/nginx/default.d/
COPY ./nginx/pam_nginx /etc/pam.d/nginx
COPY ./supervisor/*.ini /etc/supervisord.d/
COPY ./docker-entrypoint.sh /

RUN echo "###### install nginx pam auth module ######" && \
    rpm -ivh /tmp/nginx-module-auth-pam-1.5.2-1.el7.x86_64.rpm && \
    rm -f /tmp/nginx-module-auth-pam-1.5.2-1.el7.x86_64.rpm && \
    mkdir /etc/pki/nginx/ && \
    groupadd -g 42 shadow && \
    chgrp shadow /etc/gshadow && \
    chgrp shadow /etc/shadow && \
    chgrp shadow /sbin/unix_chkpwd && \
    chgrp shadow /usr/bin/chage && \
    chmod 2755 /sbin/unix_chkpwd && \
    chmod 2755 /usr/bin/chage && \
    chmod 640 /etc/shadow && \
    chmod 640 /etc/gshadow && \
    gpasswd -a nginx shadow && \
    echo "###### update-ca-trust ######" && \
    update-ca-trust && \
    echo "###### setup supervisord ######" && \
    sed -i "s/nodaemon=false/nodaemon=true/g" /etc/supervisord.conf

USER 0
ENTRYPOINT ["/docker-entrypoint.sh"]

