# logio

Work in Progress

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

## References

* [Log.io](http://logio.org/)
* [Docker Homepage](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Docker Userguide](https://docs.docker.com/userguide/)
