#!/bin/sh

# CREATED:
# vitaliy.natarov@yahoo.com
#
# Unix/Linux blog:
# http://linux-notes.org
# Vitaliy Natarov
#

# Install libs and some utilites fro php7 
apt-get install -y wget curl git vim make checkinstall build-essential libtool gettext libpcre3 libpcre3-dev libldap2-dev libpq-dev libxslt-dev libxpm-dev libmysqlclient-dev libgmp3-dev libpng12-dev libpng-dev libfreetype6-dev autoconf re2c bison libssl-dev libcurl4-openssl-dev pkg-config openssl libpng-dev libpspell-dev librecode-dev libreadline-dev libjpeg-dev libxml2 libxml2-dev libbz2-dev libmcrypt-dev libicu-dev libltdl-dev  libcurl3

# Downloads PHP7
cd /usr/src && wget http://be2.php.net/get/php-7.0.2.tar.gz/from/this/mirror -O php-7.0.2.tar.gz && tar -xzf php-*.tar.gz

# Configurations
cd php-* && ./buildconf --force 

CONFIGURE_STRING="--prefix=/usr/local/php7 \
                  --with-config-file-path=/usr/local/etc \
                  --with-config-file-scan-dir=/usr/local/php7/etc/conf.d \
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
                  --disable-short-tags \
                  --enable-phpdbg \
                  --with-readline \
                  --with-gettext \
                  --enable-opcache \
                  --enable-xdebug \
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
                  --bindir=/usr/local/bin \
                  --sbindir=/usr/local/sbin \
                  --libdir=/usr/local/php7/lib \
                  --includedir=/usr/local/php7/include \
                  --mandir=/usr/local/php7"

 # just install
 #./configure $CONFIGURE_STRING && make && make install

 # Create a .deb package of PHP7 with php7-fpm
./configure $CONFIGURE_STRING
checkinstall
# Install the pachage og PHP7
dpkg -i /usr/src/php-7.0.2/php_7*.deb


# create the configuration structure
mkdir /usr/local/php7/etc/conf.d

# copy my template files 
cd /usr/local/src && git clone https://github.com/SebastianUA/Nginx-1.9-PHP-7-PHP7-FPM.git && cp -rf /usr/local/src/Nginx-1.9-PHP-7-PHP7-FPM /usr/local/src
cp -rf /usr/local/src/php/fpm/*.ini /usr/local/etc/
cp -rf /usr/local/src/php/mods-available/* /usr/local/php7/etc/conf.d/
cp -rf /usr/local/src/php/fpm/pool.d/www.conf /usr/local/php7/etc/php-fpm.d/www.conf
cp -rf /usr/local/src/php/fpm/php-fpm.conf /usr/local/php7/etc/php-fpm.conf

# Add init script for PHP7-FPM
cp -rf /usr/local/src/php/php7-fpm /etc/init.d/
cp -rf /usr/local/src/php/php7-fpm.service /lib/systemd/system/
systemctl enable php7-fpm.service
systemctl daemon-reload

#cd /etc/init.d/ && wget http://linux-notes.org/wp-content/uploads/files/php7-fpm
chmod +x /etc/init.d/php7-fpm
chmod +x /lib/systemd/system/php7-fpm.service
#update-rc.d php7-fpm defaults

#Install composer
cd /usr/local/src && curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Start PHP7-FPM
 #service php7-fpm restart
 systemctl restart php7-fpm.service
echo "-----------------------------";
echo "------------DONE!------------";
echo "-----------------------------";

