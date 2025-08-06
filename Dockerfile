FROM richarvey/nginx-php-fpm:latest

# Install Node.js 20 to fix engine warnings
RUN apk add --no-cache nodejs npm

# Set working directory
WORKDIR /var/www/html

# Copy package files first for better caching
COPY package*.json ./
COPY composer*.json ./

# Install dependencies
RUN npm install
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Copy all application files
COPY . .

# Build frontend assets AFTER copying all files
RUN npm run build

# Move manifest from .vite subdirectory to build root where Laravel expects it
RUN mv public/build/.vite/manifest.json public/build/manifest.json

# Verify the manifest exists after build
RUN echo "=== Checking build output ===" && \
    ls -la public/build/ && \
    ls -la public/build/.vite/ && \
    cat public/build/manifest.json

# Run composer scripts
RUN composer run-script post-autoload-dump

# Clean up npm to reduce image size
RUN npm prune --production && npm cache clean --force

# Configure nginx to run on port 80
RUN sed -i 's/listen 80/listen 80/g' /etc/nginx/sites-available/default.conf

# Set permissions
RUN chown -R nginx:nginx /var/www/html && \
    chmod -R 755 /var/www/html/storage && \
    chmod -R 755 /var/www/html/bootstrap/cache

# IMPORTANT: Verify files still exist after permissions change
RUN echo "=== Final verification ===" && \
    ls -la public/build/manifest.json

# Expose port 80
EXPOSE 80

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
