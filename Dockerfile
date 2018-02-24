FROM ubuntu

MAINTAINER Aleks Bujko <a3ujko@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV DRUPAL_VERSION 8.4.5
ENV APACHE_LOG_DIR /var/log/apache2

# Install packages.
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y --no-install-recommends apt-utils \
	software-properties-common \
	python-software-properties
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php && apt-get update
RUN apt-get install -y \
	vim \
	php7.2 \
	php7.2-curl \
	php7.2-gd \
	php7.2-json \
	php7.2-mbstring \
	php7.2-cli \
	php7.2-xml \
	apache2 \
	libapache2-mod-php7.2 \
	mysql-server \
	php7.2-mysql \
	curl \
	openssh-server \
	wget \
	unzip \
	cron \
	git \
	gnupg \
	supervisor
RUN apt-get clean

# Setup PHP.
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php/7.2/apache2/php.ini
RUN sed -i 's/display_errors = Off/display_errors = On/' /etc/php/7.2/cli/php.ini

# Setup Apache.
RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
RUN sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/' /etc/apache2/sites-available/default-ssl.conf
RUN echo "Listen 8080" >> /etc/apache2/ports.conf
RUN echo "Listen 8081" >> /etc/apache2/ports.conf
RUN echo "Listen 8443" >> /etc/apache2/ports.conf
RUN sed -i 's/VirtualHost \*:80/VirtualHost \*:\*/' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's/VirtualHost _default_:443/VirtualHost _default_:8443/' /etc/apache2/sites-available/default-ssl.conf
RUN a2enmod rewrite
RUN a2enmod ssl
RUN a2ensite default-ssl.conf
RUN /etc/init.d/apache2 start

# alternative to　"mysql_secure_installation"
RUN /etc/init.d/mysql start && \
	mysql -u root -e "DELETE FROM mysql.user WHERE User=''" && \
	mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1')" && \
	mysql -u root -e "DROP DATABASE IF EXISTS test" && \
	mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'" && \
	mysql -u root -e "CREATE DATABASE proj_drupal CHARACTER SET utf8 COLLATE utf8_general_ci" && \
	mysql -u root -e "CREATE USER drupal@localhost IDENTIFIED BY 'pass'" && \
	mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON proj_drupal.* TO 'drupal'@'localhost' IDENTIFIED BY 'pass'" && \
	mysql -u root -e "FLUSH PRIVILEGES" && \
	/etc/init.d/mysql stop

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Install Drush 8.
RUN composer global require drush/drush:8.*
RUN composer global update
# RUN export PATH="$HOME/.composer/vendor/bin:$PATH"
RUN ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# Install Drupal Console.
RUN curl https://drupalconsole.com/installer -L -o drupal.phar && \
	mv drupal.phar /usr/local/bin/drupal && \
	chmod +x /usr/local/bin/drupal
RUN drupal init

# Install Drupal.
RUN rm -rf /var/www
RUN cd /var && \
	drush dl drupal-$DRUPAL_VERSION && \
mv /var/drupal* /var/www
RUN mkdir -p /var/www/sites/default/files && \
	chmod a+w /var/www/sites/default -R && \
	mkdir -p /var/www/sites/all/modules/contrib && \
	mkdir /var/www/sites/all/modules/custom && \
	mkdir -p /var/www/sites/all/themes/contrib && \
	mkdir /var/www/sites/all/themes/custom && \
	cp /var/www/sites/default/default.settings.php /var/www/sites/default/settings.php && \
	cp /var/www/sites/default/default.services.yml /var/www/sites/default/services.yml && \
	chmod 0664 /var/www/sites/default/settings.php && \
	chmod 0664 /var/www/sites/default/services.yml && \
chown -R www-data:www-data /var/www/

# exspose http, mysql
EXPOSE 80 3306 22 443

# Setup Supervisor.
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n"]