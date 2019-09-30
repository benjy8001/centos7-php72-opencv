FROM benjy80/centos7-opencv

RUN yum install -y \
    httpd \
    rh-php72 \
    rh-php72-php \
    rh-php72-php-mysqlnd \
    rh-php72-php-bcmath \
    rh-php72-php-fpm \
    rh-php72-php-gd \
    rh-php72-php-intl \
    rh-php72-php-ldap \
    rh-php72-php-mbstring \
    rh-php72-php-pecl-imagick \
    rh-php72-php-soap \
    rh-php72-php-xmlrpc \
    rh-php72-php-xdebug \
    rh-php72-php-devel \
    gcc-c++ \
    make

# Conf PHP
ADD ./config/custom.ini /etc/opt/rh/rh-php72/php.d/custom.ini
RUN ln -s /opt/rh/rh-php72/root/usr/bin/php /usr/bin/php
RUN ln -s /opt/rh/rh-php72/root/usr/bin/phpize /usr/bin/phpize
RUN ln -s /opt/rh/rh-php72/root/usr/bin/php-config /usr/bin/php-config

# Conf Apache
RUN ln -s /opt/rh/httpd24/root/etc/httpd/conf.d/rh-php72-php.conf /etc/httpd/conf.d/
RUN ln -s /opt/rh/httpd24/root/etc/httpd/conf.modules.d/15-rh-php72-php.conf /etc/httpd/conf.modules.d/
RUN ln -s /opt/rh/httpd24/root/etc/httpd/modules/librh-php72-php7.so /etc/httpd/modules/
ADD ./config/vhost.conf /etc/httpd/conf.d/local.conf

# Composer
RUN php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/local/bin --filename=composer \
    && chmod +x /usr/local/bin/composer

# Node stable release
RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash - && \
    yum install -y nodejs

# Build & conf PHP opencv
SHELL [ "/usr/bin/scl", "enable", "devtoolset-7" ]
RUN export PKG_CONFIG=/usr/bin/pkg-config && export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib64/pkgconfig/ && export LD_LIBRARY_PATH="/usr/local/lib64/" && \
    git clone https://github.com/php-opencv/php-opencv.git && \
    cd php-opencv && \
    phpize && \
    ./configure --with-php-config=/usr/bin/php-config && \
    make && make test && make install && \
    echo "extension=opencv.so" > /etc/opt/rh/rh-php72/php.d/opencv.ini && \
    cd ../ && \
    rm -R php-opencv

RUN mkdir -p /usr/share/OpenCV/ && ln -s /usr/local/share/opencv4/* /usr/share/OpenCV/

# Cleaning
RUN yum remove -y gcc-c++ make cmake gcc && yum clean all && yum -y autoremove

EXPOSE 80 443
VOLUME /var/www/html
WORKDIR /var/www/html

CMD /usr/sbin/httpd -c "ErrorLog /dev/stdout" -DFOREGROUND
