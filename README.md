Log.io inside a resuable Docker container.

# Make It Short!

You can view any logs in your browser!

First start the server!

~~~~
$ docker run -d \
    -p 28778:28778 \
    --name logio \
    blacklabelops/logio
~~~~

> Browser: Localhost: http://localhost:28778/, Docker-Tools (Windows, Mac): http://192.168.99.100:28778/

Now start Harvesters on your log files!

~~~~
$ docker run -d \
    -e "LOGIO_HARVESTER_LOGFILES=/home/logio/test.log" \
    --link logio:logio \
    --name harvester \
    blacklabelops/logio harvester
~~~~

Create the log file and write something!

~~~~
$ docker exec harvester bash -c "touch /home/logio/test.log"
$ docker exec harvester bash -c "echo "Hello World" >> /home/logio/test.log"
~~~~

# Webserver Admin Account

You can set username and password for the admin account with the environment variables
LOGIO_ADMIN_USER and LOGIO_ADMIN_PASSWORD.

Example:

~~~~
$ docker run -d \
    -p 28778:28778 \
    -e "LOGIO_ADMIN_USER=admin" \
    -e "LOGIO_ADMIN_PASSWORD=yourpasswordhere" \
    --name logio \
    blacklabelops/logio
~~~~

> Access will be secured by http auth.

# Webserver https

This container supports HTTPS. Just enter a DName with the environment variable LOGIO_CERTIFICATE_DNAME and the container creates a self-signed certificate. You have to pass Distinguished Name (DN). The certificate is generated with the Distinguished Name. This is a DN-Example:

~~~~
/CN=SBleul/OU=Blacklabelops/O=blacklabelops.net/L=Munich/C=DE
~~~~

  * CN = Your name
  * OU = Your organizational unit.
  * O = Organisation name.
  * L = Location, e.g. town name.
  * C = Locale of your county.

~~~~
$ docker run -d \
    -p 28778:28778 \
    -e "LOGIO_ADMIN_USER=admin" \
    -e "LOGIO_ADMIN_PASSWORD=yourpasswordhere" \
    -e "LOGIO_CERTIFICATE_DNAME=/CN=SBleul/OU=Blacklabelops/O=blacklabelops.com/L=Munich/C=DE" \
    --name logio \
    blacklabelops/logio
~~~~

> Note: Webserver will use same port for HTTPS!

Using your own certificates: Name your certificate 'server.crt' and key 'server.key' and mount them inside the
container at location '/opt/server/keys'.

Example:

~~~~
$ docker run -d \
    -p 28778:28778 \
    -e "LOGIO_ADMIN_USER=admin" \
    -e "LOGIO_ADMIN_PASSWORD=yourpasswordhere" \
    -e "LOGIO_CERTIFICATE_DNAME=HTTPS" \
    -v /yourcertificatepath:/opt/server/keys \
    --name logio \
    blacklabelops/logio
~~~~

> Note: Webserver will use same port for HTTPS!

# Harvest Root Files

Yes, you can also harvest files under root permissions, just start the harvest container
as user root!

~~~~
$ docker run -d \
    -e "LOGIO_HARVESTER_LOGFILES=/var/log/yum.log" \
    --link logio:logio \
    --name harvester \
    --user root \
    blacklabelops/logio harvester
~~~~

> The user parameter works both with username and userid. Note: This container only knows users root (uid:0) and logio (uid:1000). In order to introduce new users, you will have to extend the image!

# Harvester Crawl for Log Files

Log file pattern with the ability to define file patterns.

~~~~
$ docker run -d \
  -e "LOGS_DIRECTORIES=/var/log" \
  --link logio:logio \
	-e "LOG_FILE_PATTERN=*" \
  --name harvester \
  --user root \
  blacklabelops/logio harvester
~~~~

> Attaches to all files inside those folders

## References

* [Log.io](http://logio.org/)
* [Docker Homepage](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Docker Userguide](https://docs.docker.com/userguide/)
