# ttyd 

start ttyd with pam auth using nginx reverse proxy.

* Environment

* PORT
   * listen port
* USER
   * user name
   * `default: root`
* USER_ID
   * if USER is not root, you can specify UID.
   * `default: 1000`
* PASSWORD
   * user password
   * if it's not set, random passwd is generated.
       * see container log
* NOSSL
   * disable https. (true/false)
   * `default: false`
