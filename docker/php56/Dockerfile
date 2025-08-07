FROM php:5.6-fpm

# Argumentos de build
ARG DEBIAN_FRONTEND=noninteractive

# Instalar dependências do sistema (compatível com versões antigas)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng12-dev \
    libmcrypt-dev \
    libxml2-dev \
    zip \
    unzip \
    nginx \
    supervisor \
    cron \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libgd-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensões PHP para 5.6
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mbstring \
        mcrypt \
        gd \
        zip \
        opcache

# Instalar Composer (versão compatível com PHP 5.6)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=1.10.26

# Configurar PHP
COPY php.ini /usr/local/etc/php/php.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Configurar diretório de trabalho
WORKDIR /var/www/html

# Configurar usuário
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Copiar script de entrada
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expor porta do PHP-FPM
EXPOSE 9000

# Comando de entrada
ENTRYPOINT ["/entrypoint.sh"]
