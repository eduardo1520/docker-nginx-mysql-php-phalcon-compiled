# docker-nginx-mysql-php-phalcon-compiled
Contains docker file to createe a container with mysql, nginx, php and phalcon framework

###Contents

**nginx** 1.9.12 compiled with (--with-http_gzip_static_module --with-pcre --with-http_realip_module --with-http_ssl_module --with-file-aio --with-ipv6)

**mysql** 5.7.11 installed from apt

**php** 5.6.18 compiled with (--disable-cgi --enable-fpm --enable-mysqlnd --with-curl --with-openssl --with-config-file-path="$PHP_INI_DIR" --with-config-file-scan-dir="$PHP_INI_DIR/conf.d")

**php-xdebug** 2.3.3 compiled with (--enable-xdebug --with-php-config=/usr/local/bin/php-config)

**cphalcon** 2.0.10 compiled defaults

**phalcon-devtools** master
