# ==========================================
# Stage 1: Vendor Builder (Composer)
# ==========================================
FROM composer:2 AS vendor-builder

WORKDIR /app

# Copy dependency manifests
COPY src/composer.json src/composer.lock ./

# Install production dependencies with optimized classmap
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist \
    --optimize-autoloader

# ==========================================
# Stage 2: Production PHP-FPM Runtime
# ==========================================
FROM php:8.3-fpm-alpine

# Install system dependencies & PHP extensions
RUN apk add --no-cache \
    mysql-client \
    curl \
    libzip-dev \
    icu-dev \
    && docker-php-ext-install pdo pdo_mysql intl opcache

# Install composer binary for runtime utilities if ever needed
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy application source
COPY src/ /var/www/html/

# Copy pre-built vendor packages from Stage 1 into the app AND a fallback backup directory
COPY --from=vendor-builder /app/vendor/ /var/www/html/vendor/
COPY --from=vendor-builder /app/vendor/ /var/www/vendor/

# Copy and setup entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set directory permissions
RUN chown -R www-data:www-data /var/www/html /var/www/vendor

EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
