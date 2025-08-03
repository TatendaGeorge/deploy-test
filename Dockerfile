# Build stage for frontend assets
FROM node:20-alpine as node-builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Verify build was successful
RUN ls -la public/build/manifest.json

# Production stage
FROM richarvey/nginx-php-fpm:latest

WORKDIR /var/www/html

# Copy composer files first
COPY composer*.json ./

# Install composer dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Copy application files
COPY . .

# Copy built assets from node builder (this is crucial!)
COPY --from=node-builder /app/public/build ./public/build

# Verify assets were copied correctly
RUN ls -la public/build/manifest.json

# Run composer scripts after copying all files
RUN composer run-script post-autoload-dump

# Set permissions
RUN chown -R nginx:nginx /var/www/html && \
    chmod -R 755 /var/www/html/storage && \
    chmod -R 755 /var/www/html/bootstrap/cache

# Image config
ENV SKIP_COMPOSER 1
ENV WEBROOT /var/www/html/public
ENV PHP_ERRORS_STDERR 1
ENV RUN_SCRIPTS 1
ENV REAL_IP_HEADER 1

# Laravel config
ENV APP_ENV production
ENV APP_DEBUG false
ENV LOG_CHANNEL stderr
ENV COMPOSER_ALLOW_SUPERUSER 1

CMD ["/start.sh"]
