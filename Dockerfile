FROM debian:jessie

MAINTAINER Natarov Vitaliy <vitaliy.natarov@yahoo.com>

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# update the resources first
RUN apt-get -y update

##########################################################################################################################################################
#MYSQL 5.6
# https://github.com/docker-library/mysql/tree/2e80e5ff6aa7d3a09723ad40f5954a0563dbac29/5.6
##########################################################################################################################################################
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

RUN mkdir /docker-entrypoint-initdb.d

# FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
# File::Basename
# File::Copy
# Sys::Hostname
# Data::Dumper
RUN apt-get update && apt-get install -y perl pwgen --no-install-recommends && rm -rf /var/lib/apt/lists/*

# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5

ENV MYSQL_MAJOR 5.6
ENV MYSQL_VERSION 5.6.28-1debian8

RUN echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN { \
            echo mysql-community-server mysql-community-server/data-dir select ''; \
            echo mysql-community-server mysql-community-server/root-pass password ''; \
            echo mysql-community-server mysql-community-server/re-root-pass password ''; \
            echo mysql-community-server mysql-community-server/remove-test-db select false; \
      } | debconf-set-selections \
      && apt-get update && apt-get install -y mysql-server="${MYSQL_VERSION}" && rm -rf /var/lib/apt/lists/* \
      && rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql

# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf \
      && echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
      && mv /tmp/my.cnf /etc/mysql/my.cnf

#VOLUME /var/lib/mysql

COPY docker-entrypoint-mysql.sh /entrypoint-mysql.sh
RUN chmod +x /entrypoint-mysql.sh
ENTRYPOINT ["/entrypoint-mysql.sh"]

##########################################################################################################################################################
# Redis 3
# https://github.com/docker-library/redis/tree/master/3.0
##########################################################################################################################################################
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
#RUN groupadd -r redis && useradd -r -g redis redis

#RUN apt-get update
#RUN DEBIAN_FRONTEND=noninteractive apt-get -y install libc6-dev-i386

#RUN cd /usr/local/src/ && wget http://download.redis.io/releases/redis-3.0.6.tar.gz && tar xzf /usr/local/src/redis-* && cd /usr/local/src/redis-* && make 32bit && make install clean


# Define mountable directories.
#VOLUME ["/data"]

# Define working directory.
#WORKDIR /data

#========================
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r redis && useradd -r -g redis redis

RUN apt-get update && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
      && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture)" \
      && curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture).asc" \
      && gpg --verify /usr/local/bin/gosu.asc \
      && rm /usr/local/bin/gosu.asc \
      && chmod +x /usr/local/bin/gosu

ENV REDIS_VERSION 3.0.6
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-3.0.6.tar.gz
ENV REDIS_DOWNLOAD_SHA1 4b1c7b1201984bca8f7f9c6c58862f6928cf0a25

# for redis-sentinel see: http://redis.io/topics/sentinel
RUN buildDeps='gcc libc6-dev make' \
      && set -x \
      && apt-get update && apt-get install -y $buildDeps --no-install-recommends \
      && rm -rf /var/lib/apt/lists/* \
      && mkdir -p /usr/src/redis \
      && curl -sSL "$REDIS_DOWNLOAD_URL" -o redis.tar.gz \
      && echo "$REDIS_DOWNLOAD_SHA1 *redis.tar.gz" | sha1sum -c - \
      && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
      && rm redis.tar.gz \
      && make -C /usr/src/redis \
      && make -C /usr/src/redis install \
      && rm -r /usr/src/redis \
      && apt-get purge -y --auto-remove $buildDeps

RUN mkdir /data && chown redis:redis /data
#VOLUME ["/data"]
#WORKDIR /data

RUN mkdir /etc/redis

COPY /redis/redis.conf /etc/redis/

#
COPY docker-entrypoint-redis.sh /entrypoint-redis.sh
RUN chmod +x /entrypoint-redis.sh
ENTRYPOINT ["/entrypoint-redis.sh"]

##########################################################################################################################################################
#PHP 7 with PHP7-FPM
##########################################################################################################################################################

# update the resources first
RUN apt-get -y update

# install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor unzip wget curl git vim make checkinstall build-essential libtool gettext libpcre3 libpcre3-dev libldap2-dev libpq-dev libxslt-dev libxpm-dev libmysqlclient-dev libgmp3-dev libpng12-dev libpng-dev libfreetype6-dev autoconf re2c bison libssl-dev libcurl4-openssl-dev pkg-config openssl libpng-dev libpspell-dev librecode-dev libreadline-dev libjpeg-dev libxml2 libxml2-dev libbz2-dev libmcrypt-dev libicu-dev libltdl-dev libcurl3

# Downloads PHP7
RUN cd /usr/local/src && wget http://be2.php.net/get/php-7.0.2.tar.gz/from/this/mirror -O /usr/local/src/php-7.0.2.tar.gz && tar -xzf /usr/local/src/php-*.tar.gz

WORKDIR /usr/local/src/php-7.0.2

# Configurations
RUN cd /usr/local/src/php-* && ./buildconf --force 

# Create a .deb package of PHP7 with php7-fpm
RUN ./configure --prefix=/usr/local/php7 \
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
                  --mandir=/usr/local/php7

RUN make && make install 

# Run checkinstall
#RUN checkinstall
# Install the pachage og PHP7
#RUN dpkg -i  /usr/local/src/php-7.0.2/php_7.0.2-1_amd64.deb

# create the configuration structure
RUN mkdir /usr/local/php7/etc/conf.d
RUN mkdir -p /usr/local/etc
RUN mkdir -p /usr/local/php7/etc/conf.d
RUN mkdir -p /usr/local/php7/etc/php-fpm.d

# copy my template files 
COPY php/fpm/php.ini /usr/local/etc
COPY php/mods-available/* /usr/local/php7/etc/conf.d/
COPY php/fpm/pool.d/www.conf /usr/local/php7/etc/php-fpm.d/www.conf
COPY php/fpm/php-fpm.conf /usr/local/php7/etc/php-fpm.conf

# Add init script for PHP7-FPM
COPY php/php7-fpm /etc/init.d/
COPY php/php7-fpm.service /lib/systemd/system/

#RUN systemctl enable php7-fpm.service
#RUN systemctl daemon-reload

#cd /etc/init.d/ && wget http://linux-notes.org/wp-content/uploads/files/php7-fpm
RUN chmod +x /etc/init.d/php7-fpm
RUN chmod +x /lib/systemd/system/php7-fpm.service
#update-rc.d php7-fpm defaults

#Install composer
RUN cd /usr/local/src && curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install phpredis
#RUN cd /usr/local/src && git clone https://github.com/phpredis/phpredis /usr/local/src/phpredis && cd /usr/local/src/phpredis
 RUN cd /usr/local/src && wget https://github.com/nicolasff/phpredis/zipball/master -O /usr/local/src/phpredis.zip && unzip /usr/local/src/phpredis.zip
#WORKDIR /usr/local/src/phpredis-phpredis-fc673f5
RUN cd /usr/local/src/phpredis-* && /usr/local/bin/phpize && ./configure
RUN make && make install

#VOLUME ["/usr/share/nginx/html"]

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
COPY nginx/default.conf /etc/nginx/conf.d/
COPY nginx/test.html /usr/share/nginx/html/
COPY nginx/php_info.php /usr/share/nginx/html/

######################################
# MAGENTO 2
# https://github.com/magento/magento2
######################################

WORKDIR /usr/local/src/
RUN cd /usr/local/src/ && git clone https://github.com/magento/magento2.git
RUN ls -al /usr/local/src/

WORKDIR /usr/share/nginx/html/magento2
RUN git clone https://github.com/magento/magento2 /usr/share/nginx/html/magento2
RUN ls -al /usr/share/nginx/html/

RUN chown -R www-data. /usr/share/nginx/
RUN chmod -R 755 /usr/share/nginx
RUN find /usr/share/nginx/html -type f -exec chmod 644 {} \;
RUN find /usr/share/nginx/html -type d -exec chmod 755 {} \;

# Conf for MAGENTO 2
# COPY nginx/magento.conf /etc/nginx/conf.d/ 

VOLUME ["/usr/share/nginx/html"]
##########################################################################################################################################################

# clean packages
RUN apt-get clean
RUN rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

RUN cp /etc/hosts /hosts

#RUN echo 192.168.103.66 m2.demo > /hosts; ping -c 4 m2.demo

RUN mkdir -p -- /lib-override && cp /lib/x86_64-linux-gnu/libnss_files.so.2 /lib-override
RUN perl -pi -e 's:/etc/hosts:/hosts:g' /lib-override/libnss_files.so.2
ENV LD_LIBRARY_PATH /lib-override
#OR use the following str:
#perl -pi -e 's:/etc/hosts:/hosts:g' /lib/x86_64-linux-gnu/libnss_files.so.2


COPY supervisord.conf /etc/supervisor/conf.d/

# Hack for initctl
# See: https://github.com/dotcloud/docker/issues/1024
#RUN dpkg-divert --local --rename --add /sbin/initctl
#RUN ln -s /bin/true /sbin/initctl

EXPOSE 22 80 443 9000 6379 3306

# redis
#CMD ["redis-server", "/etc/redis/redis.conf"]
#CMD ["redis-server"]

# mysql
#CMD ["mysqld"]

# php-fpm and ngninx
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
 #CMD ["nginx", "-g", "daemon off;"]
 #CMD ["systemctl restart php7-fpm.service"]
##########################################################################################################################################################