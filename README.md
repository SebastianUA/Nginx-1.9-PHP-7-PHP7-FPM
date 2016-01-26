# Nginx-1.9-PHP-7-PHP7-FPM
Install Nginx-1.9 with PHP-7 (PHP7-FPM) on Debian 8 (jessie) 

`apt-get install -y git `

`cd /usr/local/src && git clone https://github.com/SebastianUA/Nginx-1.9-PHP-7-PHP7-FPM.git`


# DOCKER

Basic usage inside the repos root dir:

`docker build -t <nameofyourchoosing> .`

Example:
`docker build -t m2 .`


then:

`docker run -d -p 127.0.0.1:80:80 -v /var/www:/var/www m2`

OR

`docker run -d -p 80:80 -i -t m2 `

If you want to start bash in docker container):

`docker run -i -t m2 /bin/bash`

If you want use /etc/hosts:

` docker run -d -p 80:80 -v /etc/hosts:/hosts -i -t m2`

