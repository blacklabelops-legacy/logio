[![Circle CI](https://circleci.com/gh/blacklabelops/logio/tree/master.svg?style=shield)](https://circleci.com/gh/blacklabelops/logio/tree/master)
[![Image Layers](https://badge.imagelayers.io/blacklabelops/logio:latest.svg)](https://imagelayers.io/?images=blacklabelops/logio:latest 'Get your own badge on imagelayers.io')
[![Docker Repository on Quay](https://quay.io/repository/blacklabelops/logio/status "Docker Repository on Quay")](https://quay.io/repository/blacklabelops/jenkins)

Leave a message and ask questions on Hipchat: [blacklabelops/hipchat](https://www.hipchat.com/geogBFvEM)

# Make It Short!

In short, this container puts an UI on your Docker logs!

Recommended: Docker-Compose! Just curl the files and modify the environment-variables inside
the .env-files.

~~~~
$ curl -O https://raw.githubusercontent.com/blacklabelops/logio/master/docker-compose.yml
$ docker-compose up -d
~~~~

> Browser: Localhost: http://localhost:28778/, Docker-Tools (Windows, Mac): http://192.168.99.100:28778/

First start the server!

~~~~
$ docker run -d \
    -p 28778:28778 \
    --name logio \
    quay.io/blacklabelops/logio
~~~~

> Browser: Localhost: http://localhost:28778/, Docker-Tools (Windows, Mac): http://192.168.99.100:28778/

Now Harvest Your Docker Logs!

~~~~
$ docker run -d \
	-v /var/lib/docker:/var/lib/docker \
  -e "LOGS_DIRECTORIES=/var/lib/docker" \
  --link logio:logio \
	-e "LOG_FILE_PATTERN=*.log" \
  --name harvester \
  --user root \
  quay.io/blacklabelops/logio harvester
~~~~

> This will harvest all your Docker logfiles and stream them to your webserver.

# How It Works

You can view any logs in your browser!

First start the server!

~~~~
$ docker run -d \
    -p 28778:28778 \
    --name logio \
    quay.io/blacklabelops/logio
~~~~

> Browser: Localhost: http://localhost:28778/, Docker-Tools (Windows, Mac): http://192.168.99.100:28778/

Now start Harvesters on your log files!

~~~~
$ docker run -d \
    -e "LOGIO_HARVESTER_LOGFILES=/home/logio/test.log" \
    --link logio:logio \
    --name harvester \
    quay.io/blacklabelops/logio harvester
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
    quay.io/blacklabelops/logio
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
    quay.io/blacklabelops/logio
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
    quay.io/blacklabelops/logio
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
    quay.io/blacklabelops/logio harvester
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
  quay.io/blacklabelops/logio harvester
~~~~

> Attaches to all files inside those folders

# Vagrant

Vagrant is fabulous tool for pulling and spinning up virtual machines like docker with containers. I can configure my development and test environment and simply pull it online. And so can you! Install Vagrant and Virtualbox and spin it up. Change into the project folder and build the project on the spot!

~~~~
$ vagrant up
$ vagrant ssh
[vagrant@localhost ~]$ cd /vagrant
[vagrant@localhost ~]$ docker-compose up
~~~~

> Log.io will be available on localhost:28778 on the host machine.

Vagrant does not leave any docker artifacts on your beloved desktop and the vagrant image can simply be destroyed and repulled if anything goes wrong. Test my project to your heart's content!

First install:

* [Vagrant](https://www.vagrantup.com/)
* [Virtualbox](https://www.virtualbox.org/)

## References

* [Log.io](http://logio.org/)
* [Docker Homepage](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Docker Userguide](https://docs.docker.com/userguide/)
