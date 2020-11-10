# docker-ttyd

Dockerfile to start web based terminal(ttyd) with pam auth using nginx reverse proxy.

# Usage

```
docker run -d -p 443:8080 -e USER=foo -e PASSWORD=mypassword --name ttyd tmatsuo/ttyd
```

Access https://your-server-ip/ and login with ID=foo,PASSWORD=mypassword.

## Environment

* PORT
   * listen port
* USER
   * user name
   * `default: root`
* USER_ID
   * if USER is not root, you can specify UID.
   * `default: 1000`
* GROUP_ID
   * if USER is not root, you can specify GID.
   * `default: (useradd command generates '1000' automatically)`
* PASSWORD
   * user password
   * if it's not set, random passwd is generated.
       * see container log
* ENABLE_SUDO (true/false)
   * specified `USER` can use sudo command with no password.
   * `default: false`
* TTYD_OPTS
   * ttyd args
   * `default: -p 10022 -P 30 -i lo /bin/bash`
       * don't change port `10022` which is specified by nginx reverse proxy.
* NOSSL
   * disable https. (true/false)
   * `default: false`
   * you can specify key and crt file if NOSSL=false
       * ex (docker run with -v option)
       * -v /path/to/server.key:/etc/pki/nginx/server.key -v /path/to/server.crt:/etc/pki/nginx/server.crt 
