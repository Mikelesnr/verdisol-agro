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

# Laravel environment config
ENV SKIP_COMPOSER 1
ENV WEBROOT /var/www/html/public
ENV PHP_ERRORS_STDERR 1
ENV RUN_SCRIPTS 1
ENV REAL_IP_HEADER 1

ENV APP_ENV production
ENV APP_DEBUG false
ENV LOG_CHANNEL stderr

# Laravel setup
RUN cd /var/www/html \
    && composer install --optimize-autoloader --no-dev \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 storage bootstrap/cache
