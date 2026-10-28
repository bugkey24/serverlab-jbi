FROM php:8.3-fpm-alpine

# Install system dependencies & PHP extensions
RUN apk add --no-cache \
    mysql-client \
    curl \
    libzip-dev \
    icu-dev \
    && docker-php-ext-install pdo pdo_mysql intl

WORKDIR /var/www/html

# Copy application source
COPY src/ /var/www/html/

# Permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 9000
CMD ["php-fpm"]
