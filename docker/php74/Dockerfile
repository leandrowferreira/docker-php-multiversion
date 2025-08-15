FROM php:7.4-fpm

# Argumentos de build
ARG DEBIAN_FRONTEND=noninteractive

# Configurar timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    gnupg \
    gosu \
    ca-certificates \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    supervisor \
    cron \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libgd-dev \
    python3 \
    dnsutils \
    librsvg2-bin \
    fswatch \
    zbar-tools \
    sqlite3 \
    libsqlite3-dev \
    libcap2-bin \
    mariadb-client \
    libkrb5-dev \
    libc-client-dev \
    libldap2-dev \
    libmagickwand-dev \
    libcurl4-openssl-dev \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Instalar extensões PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        pdo_sqlite \
        mysqli \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
        opcache \
        soap \
        intl \
        imap \
        ldap \
        xml \
        curl \
        fileinfo \
        session

# Instalar extensões via PECL
RUN pecl install redis igbinary msgpack imagick \
    && docker-php-ext-enable redis igbinary msgpack imagick

# Configurar permissões para bind em portas baixas
RUN setcap "cap_net_bind_service=+ep" /usr/local/bin/php

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar PHP
COPY php.ini /usr/local/etc/php/php.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Configurar diretório de trabalho
WORKDIR /var/www/html

# Configurar usuário
RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

# Criar diretório de runtime
RUN mkdir -p /run/php

# Copiar script de entrada
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expor portas
EXPOSE 80 9000

# Comando de entrada
ENTRYPOINT ["/entrypoint.sh"]
