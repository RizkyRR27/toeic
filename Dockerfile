# 1. Menggunakan image PHP 8.2 dengan Apache sebagai dasar
FROM php:8.2-apache

# 2. Install dependensi sistem (termasuk libzip-dev agar tidak error ext-zip)
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl

# 3. Bersihkan cache apt
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. Install ekstensi PHP yang dibutuhkan Laravel & TiDB (MySQL)
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# 5. Aktifkan modul rewrite Apache untuk routing Laravel
RUN a2enmod rewrite

# 6. Set folder kerja
WORKDIR /var/www/html

# 7. Copy semua file project ke dalam container
COPY . .

# 8. Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 9. Jalankan instalasi library Laravel tanpa dev dependencies
RUN composer install --no-dev --optimize-autoloader

# 10. Atur izin akses folder storage & cache agar tidak Error 500
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 11. Ubah Document Root Apache ke folder /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 12. Buka port 80
EXPOSE 80

# 13. OTOMATISASI: Jalankan migrasi & seeder setiap web dinyalakan
# Ini solusi karena Render Free Tier tidak bisa akses Shell secara manual
CMD php artisan migrate --force && php artisan db:seed --force && apache2-foreground