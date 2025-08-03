FROM richarvey/nginx-php-fpm:latest

# Install Node.js and npm
RUN apk add --no-cache nodejs npm

# Set working directory
WORKDIR /var/www/html

# Copy package files first for better caching
COPY package*.json ./

# Install npm dependencies
RUN npm install

# Copy application files
COPY . .

# Install composer dependencies
RUN composer install --no-dev --optimize-autoloader

# Build frontend assets
RUN npm run build

# Clean up npm dependencies to reduce image size
RUN npm prune --production && npm cache clean --force

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

# Allow composer to run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# Ensure proper permissions
RUN chown -R nginx:nginx /var/www/html && \
    chmod -R 755 /var/www/html/storage && \
    chmod -R 755 /var/www/html/bootstrap/cache

CMD ["/start.sh"]
