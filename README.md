# Dockerized Logio

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
    blacklabelops/logio
~~~~

> Browser: Localhost: http://localhost:28778/, Docker-Tools (Windows, Mac): http://192.168.99.100:28778/

Now Harvest Your Docker Logs!

~~~~
$ docker run -d \
	 -v /var/lib/docker/containers:/var/lib/docker/containers \
    -e "LOGS_DIRECTORIES=/var/lib/docker/containers" \
    --link logio:logio \
  	-e "LOG_FILE_PATTERN=*-json.log" \
    --name harvester \
    --user root \
    blacklabelops/logio harvester
~~~~

> This will harvest all your Docker logfiles and stream them to your webserver.

> Note: When you use docker-tools you may have to ssh into the machine ('docker-machine ssh') to be able to volume the directory /var/lib/docker/containers

# How It Works

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
$ docker exec harvester bash -c 'touch /home/logio/test.log'
$ docker exec harvester bash -c 'echo "Hello World" >> /home/logio/test.log'
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

You can define an arbitrary number of streams with individual streamname, directories and logfile patterns! With the environment variables:

* `LOGIO_HARVESTER1STREAMNAME`: The streamname, e.g. `MyFantasticStreamname`
* `LOGIO_HARVESTER1LOGSTREAMS`: The logfile directories, space separated, e.g.: `/var/log /testlog` or `/dir1 /dir2 /dir3`
* `LOGIO_HARVESTER1FILEPATTERN`: The logfile patterns, space separated, e.g. `*.xml *.log`

> Note that the variables must be enumerated (`1`,`2`,`3` and so on) starting from `1` for an arbitrary amount of definitions!

Log file pattern with the ability to define file patterns.

~~~~
$ docker run -d \
  -e "LOGIO_HARVESTER1STREAMNAME=teststream1" \
	-e "LOGIO_HARVESTER1LOGSTREAMS=/tests" \
	-e "LOGIO_HARVESTER1FILEPATTERN=*.xml" \
	-e "LOGIO_HARVESTER2STREAMNAME=teststream2" \
	-e "LOGIO_HARVESTER2LOGSTREAMS=/tests2" \
	-e "LOGIO_HARVESTER2FILEPATTERN=*.log *.xml" \
  --link logio:logio \
  --name harvester \
  blacklabelops/logio harvester
~~~~

> Attaches to all files matching the patterns inside those folders.

# Harvester Master Host and port

This is an example on connecting to a logio master without direct linking.

You can specify the logio master host and port with:

* LOGIO_HARVESTER_MASTER_HOST (default: `logio`)
* LOGIO_HARVESTER_MASTER_PORT (default: `28777`)

Create a test network:

~~~~
$ docker network create logio
~~~~

First start the master:

~~~~
$ docker run -d \
    -p 28778:28778 \
    --name master \
    --net logio \
    --net-alias master \
    blacklabelops/logio
~~~~

> Runs on different hostname. UI runs on http://yourdockerhost:28778.

Now connect with the slave:

~~~~
$ docker run -d \
    -e "LOGIO_HARVESTER_LOGFILES=/home/logio/test.log" \
    -e "LOGIO_HARVESTER_MASTER_HOST=master" \
    -e "LOGIO_HARVESTER_MASTER_PORT=28777" \
    --name harvester \
    --net logio \
    --user root \
    blacklabelops/logio harvester
~~~~


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
ssage and ask questions on Hipchat: [blacklabelops/hipchat](http://support.blacklabelops.com)

# References

* [Log.io](http://logio.org/)
* [Docker Homepage](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Docker Userguide](https://docs.docker.com/userguide/)
