#!/bin/sh

# CREATED:
# vitaliy.natarov@yahoo.com
#
# Unix/Linux blog:
# http://linux-notes.org
# Vitaliy Natarov
#

# Add key and repo
apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

# Install nginx
NGINX_VERSION="1.9.9-1~jessie"
apt-get update && apt-get install -y ca-certificates nginx=${NGINX_VERSION}
    
rm -rf /var/lib/apt/lists/*

#Copy some confs
cd /usr/local/src
wget https://raw.githubusercontent.com/SebastianUA/Nginx-1.9-PHP-7-PHP7-FPM/master/nginx/default.conf
wget https://raw.githubusercontent.com/SebastianUA/Nginx-1.9-PHP-7-PHP7-FPM/master/nginx/php_info.php
wget https://raw.githubusercontent.com/SebastianUA/Nginx-1.9-PHP-7-PHP7-FPM/master/nginx/test.html
cp -rf /usr/local/src/nginx/default.conf /etc/nginx/conf.d/default.conf 
cp -rf /usr/local/src/nginx/test.html /usr/share/nginx/html/
cp -rf /usr/local/src/nginx/php_info.php /usr/share/nginx/html/

# Start nginx1.9
service nginx restart

echo "-----------------------------";
echo "------------DONE!------------";
echo "-----------------------------";
