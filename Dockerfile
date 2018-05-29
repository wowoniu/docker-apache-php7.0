FROM zhiqiangvip/docker-ubuntu1404-163
MAINTAINER qiang <zhiqiangvip999@gmail.com>

#ADD PPA REPO
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive && apt-get -yq install \
	python-software-properties software-properties-common && \
	LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php && \
	apt-get update
#Install base packages
RUN DEBIAN_FRONTEND=noninteractive && apt-get -yq install \
        curl \
        git \
        unzip \
	apache2 \
        libapache2-mod-php7.2 \
        freetds-common \
	freetds-dev \
	freetds-bin \
        php7.2 \
	php7.2-fpm \
	php7.2-mysql \
	php7.2-sybase  \
        php7.2-mysql \
        php7.2-gd \
        php7.2-curl \
        php-memcache \
	php7.2-dev \
        php-pear \
	php7.2-xml \
	php7.2-soap \
	php7.2-mbstring \
	php7.2-zip \
	php7.2-bz2 \
	&& \
	rm -rf /var/lib/apt/lists/*
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

ENV ALLOW_OVERRIDE **True**


#vhost
ADD vhost.conf /etc/apache2/sites-available/vhost.conf
ADD apache2.conf /etc/apache2/apache2.conf
RUN a2enmod vhost_alias rewrite proxy proxy_fcgi
RUN a2ensite vhost

# Configure /data folder with sample app
RUN mkdir -p /data && rm -fr /var/www/html && ln -s /data /var/www/html
#ADD sample/ /data

VOLUME  ["/etc/apache2"]

#php config#####################################
#compile re2c
ADD soft/re2c-0.16.tar.gz /tmp/
WORKDIR /tmp/re2c-0.16
RUN	./configure && \
	make && \
	make install

#compile amqp
ADD soft/amqp-1.7.1.tgz /tmp/
ADD soft/rabbitmq-c-0.8.0.tar.gz /tmp/

WORKDIR /tmp/rabbitmq-c-0.8.0
RUN	./configure --prefix=/usr/local/rabbitmq-c-0.8.0 && \
	make && \
	make install
WORKDIR /tmp/amqp-1.7.1
RUN	phpize
RUN 	./configure --with-amqp --with-librabbitmq-dir=/usr/local/rabbitmq-c-0.8.0 --with-php-config=/usr/bin/php-config7.2  && \
	make && \
	make install
#开启amqp拓展/usr/lib/php/20170718/amqp.so
RUN sed -i "s/;   extension=\/path\/to\/extension\/mysqli\.so/;   extension=\/path\/to\/extension\/mysqli\.so\n   extension=\/usr\/lib\/php\/20170718\/amqp.so/g"  /etc/php/7.2/apache2/php.ini
RUN sed -i "s/;   extension=\/path\/to\/extension\/mysqli\.so/;   extension=\/path\/to\/extension\/mysqli\.so\n   extension=\/usr\/lib\/php\/20170718\/amqp.so/g"  /etc/php/7.2/cli/php.ini



#编译安装xdebug 注意：XDEBUG的配置 为了能在启动容器时进行动态配置 将配置处理移到了run.sh脚本中
#ADD soft/xdebug-2.5.5.tgz /tmp
ADD soft/xdebug-2.7.0alpha1.tgz /tmp
WORKDIR /tmp/xdebug-2.7.0alpha1
RUN phpize && \
	./configure --with-php-config=/usr/bin/php-config7.2 && \
	make && make install


#安装composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
#设置国内composer镜像源
RUN composer config -g repo.packagist composer https://packagist.phpcomposer.com

VOLUME  ["/etc/php/7.2"]


# Add image configuration and scripts
ADD run.sh /run.sh
RUN chmod 755 /*.sh

EXPOSE 80
WORKDIR /data
CMD ["/run.sh"]
