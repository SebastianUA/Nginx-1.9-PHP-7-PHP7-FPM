FROM debian:jessie

MAINTAINER Natarov Vitaliy <vitaliy.natarov@yahoo.com>

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# update the resources first
RUN apt-get -y update

##########################################################################################################################################################
#PHP 7 with PHP7-FPM
##########################################################################################################################################################

# install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor wget curl git vim make checkinstall build-essential libtool gettext libpcre3 libpcre3-dev libldap2-dev libpq-dev libxslt-dev libxpm-dev libmysqlclient-dev libgmp3-dev libpng12-dev libpng-dev libfreetype6-dev autoconf re2c bison libssl-dev libcurl4-openssl-dev pkg-config openssl libpng-dev libpspell-dev librecode-dev libreadline-dev libjpeg-dev libxml2 libxml2-dev libbz2-dev libmcrypt-dev libicu-dev libltdl-dev  libcurl3

# Downloads PHP7
RUN cd /usr/src && wget http://be2.php.net/get/php-7.0.2.tar.gz/from/this/mirror -O php-7.0.2.tar.gz && tar -xzf php-*.tar.gz

# Configurations
RUN cd php-* && ./buildconf --force 

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
RUN ./configure $CONFIGURE_STRING
RUN checkinstall
# Install the pachage og PHP7
RUN dpkg -i /usr/src/php-7.0.2/php_7*.deb


# create the configuration structure
RUN mkdir /usr/local/php7/etc/conf.d

# copy my template files 
RUN cp -rf /usr/local/src/php/fpm/*.ini /usr/local/etc/
RUN cp -rf /usr/local/src/php/mods-available/* /usr/local/php7/etc/conf.d/
RUN cp -rf /usr/local/src/php/fpm/pool.d/www.conf /usr/local/php7/etc/php-fpm.d/www.conf
RUN cp -rf /usr/local/src/php/fpm/php-fpm.conf /usr/local/php7/etc/php-fpm.conf

# Add init script for PHP7-FPM
RUN cp -rf /usr/local/src/php/php7-fpm /etc/init.d/
RUN cp -rf /usr/local/src/php/php7-fpm.service /lib/systemd/system/
RUN systemctl enable php7-fpm.service
RUN systemctl daemon-reload

#cd /etc/init.d/ && wget http://linux-notes.org/wp-content/uploads/files/php7-fpm
RUN chmod +x /etc/init.d/php7-fpm
RUN chmod +x /lib/systemd/system/php7-fpm.service
#update-rc.d php7-fpm defaults

#Install composer
RUN cd /usr/local/src && curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer


VOLUME ["/usr/share/nginx/html"]

##########################################################################################################################################################
#NGINX_1.9   
##########################################################################################################################################################

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
RUN echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

ENV NGINX_VERSION 1.9.9-1~jessie

RUN apt-get update && \
    apt-get install -y wget git ca-certificates nginx=${NGINX_VERSION} && \
    rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log


#Copy some confs
RUN cd /usr/local/src
RUN cp -rf /usr/local/src/nginx/default.conf /etc/nginx/conf.d/default.conf 
RUN cp -rf /usr/local/src/nginx/test.html /usr/share/nginx/html/
RUN cp -rf /usr/local/src/nginx/php_info.php /usr/share/nginx/html/

# Conf for MAGENTO 2
# RUN cp -rf /usr/local/src/nginx/magento.conf /etc/nginx/conf.d/ 

VOLUME ["/usr/share/nginx/html"]
##########################################################################################################################################################
#MYSQL 5.6
##########################################################################################################################################################

##########################################################################################################################################################
COPY /usr/local/src/supervisord.conf /etc/supervisor/conf.d/

EXPOSE 22 80 443 9000

#CMD ["nginx", "-g", "daemon off;"]
#CMD ["systemctl restart php7-fpm.service"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]