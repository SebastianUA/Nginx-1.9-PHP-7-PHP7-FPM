#!/bin/sh

# CREATED:
# vitaliy.natarov@yahoo.com
#
# Unix/Linux blog:
# http://linux-notes.org
# Vitaliy Natarov
#

# Install libs and some utilites fro php7 
apt-get install -y wget curl git vim make build-essential libtool gettext libpcre3 libpcre3-dev libldap2-dev libpq-dev libxslt-dev libxpm-dev libmysqlclient-dev libgmp3-dev libpng12-dev libpng-dev libfreetype6-dev autoconf re2c bison libssl-dev libcurl4-openssl-dev pkg-config openssl libpng-dev libpspell-dev librecode-dev libreadline-dev libjpeg-dev libxml2 libxml2-dev libbz2-dev libmcrypt-dev libicu-dev libltdl-dev  libcurl3

# Downloads PHP7
cd /usr/src && wget http://be2.php.net/get/php-7.0.2.tar.gz/from/this/mirror -O php-7.0.2.tar.gz && tar -xzf php-*.tar.gz

# Configurations
cd php-* && ./buildconf --force 

CONFIGURE_STRING="--prefix=/usr/php \
                  --enable-mbstring \
                  --with-curl \
                  --with-openssl \
                  --with-xmlrpc \
                  --enable-soap \
                  --enable-zip \
                  --with-gd \
                  --with-jpeg-dir \
                  --with-png-dir \
                  --with-pgsql \
                  --enable-embedded-mysqli \
                  --with-freetype-dir \
                  --enable-intl \
                  --with-xsl \
                  --with-mysqli \
                  --with-pdo-mysql \
                  --enable-pdo=shared \
                  --with-pdo-mysql=shared \
                  --with-pdo-sqlite=shared \
                  --with-pdo-pgsql=shared \
                  --with-config-file-path=/etc/php \
                  --disable-short-tags \
                  --enable-phpdbg \
                  --with-readline \
                  --with-gettext \
                  --enable-opcache \
                  --enable-debug \
                  --enable-intl \
                  --enable-mbstring \
                  --enable-pcntl \
                  --enable-sockets \
                  --enable-sysvmsg \
                  --enable-sysvsem \
                  --enable-sysvshm \
                  --enable-ftp \
                  --enable-fpm \
                  --enable-shmop \
                  --with-fpm-user=www-data \
                  --with-fpm-group=www-data \
                  --bindir=/usr/bin \
                  --sbindir=/usr/sbin \
                  --libdir=/usr/lib \
                  --includedir=/usr/include \
                  --mandir=/usr/local"

./configure $CONFIGURE_STRING && make && make install

# create the configuration structure
mkdir -p /etc/php/fpm/conf.d 
mkdir -p /etc/php/fpm/pool.d
mkdir -p /etc/php/cli/conf.d
mkdir -p /etc/php/mods-available 

#mkdir -p /var/run/sshd

# copy my template files 
cp -rf /usr/local/src/php/mods-available/* /etc/php/mods-available/
cp -rf /usr/local/src/php/fpm/*.ini /etc/php/
rm -rf /etc/php/php-fpm.conf
cp -rf /usr/local/src/php/fpm/*.conf /etc/php/
cp -rf /usr/local/src/php/fpm/conf.d/*.ini /etc/php/fpm/conf.d/
cp -rf /usr/local/src/php/fpm/pool.d/*.conf /etc/php/fpm/pool.d/

# download init script for PHP7-FPM
cd /etc/init.d && wget http://linux-notes.org/wp-content/uploads/files/php7-fpm
chmod +x /etc/init.d/php7-fpm
update-rc.d php7-fpm defaults

# Start PHP7-FPM
service php7-fpm restart

echo "-----------------------------";
echo "------------DONE!------------";
echo "-----------------------------";

