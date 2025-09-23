# Stage 1: Build frontend assets
FROM node:20-alpine AS frontend

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY resources resources
COPY vite.config.js ./
RUN npm run build

# Stage 2: Laravel + Nginx + PHP-FPM
FROM richarvey/nginx-php-fpm:3.1.6

# Copy Laravel app
COPY . /var/www/html

# Copy built frontend assets
COPY --from=frontend /app/public /var/www/html/public
COPY --from=frontend /app/resources /var/www/html/resources

# Image config
ENV WEBROOT /var/www/html/public
ENV PHP_ERRORS_STDERR 1
ENV RUN_SCRIPTS 1
ENV REAL_IP_HEADER 1
ENV APP_ENV production
ENV APP_DEBUG false
ENV LOG_CHANNEL stderr
ENV COMPOSER_ALLOW_SUPERUSER 1

# Laravel setup
WORKDIR /var/www/html

# Ensure required directories exist before Composer runs
RUN mkdir -p bootstrap/cache storage/framework storage/logs \
    && chmod -R 775 bootstrap/cache storage \
    && chown -R www-data:www-data /var/www/html

# Ensure .env exists
RUN cp .env.example .env || echo ".env already exists"

# Install Composer dependencies
RUN composer install --no-dev --optimize-autoloader

# Laravel bootstrapping
RUN php artisan key:generate --force \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# Start Nginx + PHP-FPM
CMD ["/start.sh"]
