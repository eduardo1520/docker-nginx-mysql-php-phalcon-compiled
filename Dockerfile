FROM ubuntu:15.10

RUN echo "test"

ENV PHP_VERSION '5.6.18'
ENV NGINX_VERSION '1.9.12'
ENV MYSQL_MAJOR_VERSION '5.7'
ENV MYSQL_MINOR_VERSION '5.7.11-1ubuntu15.10'
ENV PHALCON_VERSION '2.0.10'
ENV XDEBUG_VERSION '2_3_3'

ENV DEPENDENCIES 'wget libcurl4-openssl-dev libssl-dev'
ENV PHP_INI_DIR /usr/local/etc/php
RUN mkdir -p $PHP_INI_DIR/conf.d

# persistent / runtime deps
RUN apt-get update && apt-get install -y ca-certificates curl librecode0 libsqlite3-0 libxml2 git --no-install-recommends && rm -r /var/lib/apt/lists/*

# phpize deps
RUN apt-get update && apt-get install -y autoconf file g++ gcc libc-dev make pkg-config re2c wget --no-install-recommends && rm -r /var/lib/apt/lists/*

# php dependencies
RUN apt-get update && apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev --no-install-recommends && rm -r /var/lib/apt/lists/*

# nginx dependencies
RUN apt-get update && apt-get install -y libpcre3-dev libssl-dev libgeoip-dev

# Add mysql repo and public key and install mysql
RUN echo "deb http://repo.mysql.com/apt/ubuntu/ wily mysql-${MYSQL_MAJOR_VERSION}" > /etc/apt/sources.list.d/mysql.list
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5
RUN { \
        echo mysql-community-server mysql-community-server/data-dir select ''; \      
        echo mysql-community-server mysql-community-server/root-pass password ''; \      
        echo mysql-community-server mysql-community-server/re-root-pass password ''; \   
        echo mysql-community-server mysql-community-server/remove-test-db select false; \
    } | debconf-set-selections && \ 
    apt-get update && apt-get install -y mysql-server="${MYSQL_MINOR_VERSION}" && rm -rf /var/lib/apt/lists/*

# Get, compile and install nginx
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O nginx.tar.gz && \
    tar -xvf nginx.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure --with-http_gzip_static_module --with-pcre --with-http_realip_module --with-http_ssl_module --with-file-aio --with-ipv6 && \
    make && \   
    make install

# Get, compile and install PHP
RUN wget http://php.net/get/php-${PHP_VERSION}.tar.gz/from/this/mirror -O php.tar.gz && \
    tar -xvf php.tar.gz && \
    cd php-${PHP_VERSION} && \
    ./configure --disable-cgi --enable-fpm --enable-mysqlnd --with-curl --with-openssl --with-config-file-path="$PHP_INI_DIR" --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" && \
    make && \
    make install

# Get, compile and install phalcon php extension
RUN git clone --branch phalcon-v${PHALCON_VERSION} http://github.com/phalcon/cphalcon.git && \
    cd cphalcon/build && \
    ./install && \
    echo "extension = phalcon.so" >> ${PHP_INI_DIR}/php.ini

RUN git clone http://github.com/phalcon/phalcon-devtools.git && \
    cd phalcon-devtools && \
    . ./phalcon.sh && \
    ln -s phalcon.php /usr/bin/phalcon && \
    chmod ugo+x /usr/bin/phalcon

# Get, compile and install xdebug php extension
RUN git clone --branch XDEBUG_${XDEBUG_VERSION} http://github.com/xdebug/xdebug && \
    cd xdebug && \
    phpize && \
    ./configure --enable-xdebug --with-php-config=/usr/local/bin/php-config && \
    make && \
    make install && \
    echo "zend_extension = xdebug.so" >>  ${PHP_INI_DIR}/php.ini

EXPOSE 80 9000 3306
VOLUME /var/www

ADD nginx.conf /usr/local/nginx/conf/nginx.conf
ADD fastcgi.conf /usr/local/nginx/conf/fastcgi.conf
ADD php.ini /usr/local/etc/php/conf.d/php.ini
ADD php-fpm.conf /usr/local/etc/php-fpm.conf

CMD service mysql start && php-fpm && /usr/local/nginx/sbin/nginx