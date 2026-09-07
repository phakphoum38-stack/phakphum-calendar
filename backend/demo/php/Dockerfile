FROM php:8.2-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
    libzip-dev \
    unzip \
 && docker-php-ext-install pdo pdo_mysql \
 && rm -rf /var/lib/apt/lists/*

# Enable mod_rewrite and allow .htaccess overrides
RUN a2enmod rewrite && sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

COPY www/ /var/www/html/

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
