# Nginx-1.9-PHP-7-PHP7-FPM
Install Nginx-1.9 with PHP-7 (PHP7-FPM) on Debian 8 (jessie) 

`apt-get install -y git `

`cd /usr/local/src && git clone https://github.com/SebastianUA/Nginx-1.9-PHP-7-PHP7-FPM.git`


# DOCKER

Basic usage inside the repos root dir:

`docker build -t <nameofyourchoosing> .`

Example:
`docker build -t my_docker .`


then:

`docker run -d -p 127.0.0.1:80:80 -v /var/www:/var/www <nameofyourchoosing>`


