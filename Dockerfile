# Menggunakan image PHP 8.2 dengan Apache sebagai dasar
FROM php:8.2-apache

# 1. Install dependensi sistem yang dibutuhkan Laravel
# Menambahkan libzip-dev agar ekstensi zip bisa terpasang
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl

# 2. Bersihkan cache apt untuk mengurangi ukuran image
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Install ekstensi PHP yang diwajibkan Laravel & MySQL (TiDB)
# Menambahkan ekstensi 'zip' untuk mendukung Composer
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# 4. Aktifkan modul rewrite Apache agar routing Laravel jalan
RUN a2enmod rewrite

# 5. Tentukan folder kerja di dalam container
WORKDIR /var/www/html

# 6. Copy seluruh file project ke dalam container
COPY . .

# 7. Install Composer secara otomatis
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 8. Jalankan instalasi library Laravel (Composer)
# Menggunakan flag --no-dev untuk performa lebih baik di hosting
RUN composer install --no-dev --optimize-autoloader

# 9. Atur izin akses folder (Permission) agar tidak Error 500
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 10. Ubah Document Root Apache ke folder /public milik Laravel
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Membuka port 80 untuk akses web
EXPOSE 80