# Stage 1: Build frontend assets
FROM node:20-alpine AS frontend

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY resources resources
COPY vite.config.js ./
RUN npm run build

# Stage 2: Laravel backend
FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    bash curl zip unzip git \
    libpng libjpeg-turbo libwebp libzip \
    libxml2-dev libjpeg-turbo-dev libpng-dev libwebp-dev libzip-dev \
    oniguruma icu icu-dev zlib-dev \
    postgresql-dev nginx supervisor tzdata shadow \
    && docker-php-ext-install pdo pdo_mysql mbstring zip intl xml

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

COPY --from=frontend /app/public ./public
COPY --from=frontend /app/resources ./resources

COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf

RUN composer install --optimize-autoloader --no-dev \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache \
    && chown -R www-data:www-data . \
    && chmod -R 755 storage bootstrap/cache

EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
