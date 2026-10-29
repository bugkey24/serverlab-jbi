#!/bin/sh
set -e

echo "[demo-pulse-app] Initializing ServerLab Pulse runtime..."

# 1. Ensure storage and bootstrap/cache directories exist with proper permissions
mkdir -p /var/www/html/storage/framework/cache/data \
         /var/www/html/storage/framework/sessions \
         /var/www/html/storage/framework/views \
         /var/www/html/storage/app/public \
         /var/www/html/storage/logs \
         /var/www/html/bootstrap/cache

chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 2. Check if vendor/autoload.php exists (e.g., if code volume was mounted without vendor)
if [ ! -f /var/www/html/vendor/autoload.php ]; then
    echo "[demo-pulse-app] vendor/autoload.php not found. Copying pre-built vendor packages..."
    if [ -d /var/www/vendor ]; then
        cp -a /var/www/vendor /var/www/html/
        chown -R www-data:www-data /var/www/html/vendor
    else
        echo "[demo-pulse-app] Installing composer dependencies..."
        composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction
        chown -R www-data:www-data /var/www/html/vendor
    fi
fi

# 3. Check and generate APP_KEY if missing or empty
if [ -z "$APP_KEY" ]; then
    echo "[demo-pulse-app] Generating fresh cryptographic APP_KEY..."
    GENERATED_KEY="base64:$(php -r 'echo base64_encode(random_bytes(32));')"
    export APP_KEY="$GENERATED_KEY"
    echo "[demo-pulse-app] Active APP_KEY: $APP_KEY"
fi

# 4. Optional cache warming if database is ready
php artisan config:clear || true

echo "[demo-pulse-app] Ready! Starting php-fpm..."
exec "$@"
