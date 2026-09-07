FROM php:8.4-cli

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     git \
     unzip \
     zip \
     libzip-dev \
  && docker-php-ext-install zip pdo pdo_sqlite \
  && rm -rf /var/lib/apt/lists/*

# Copy composer from official composer image
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /workspaces/phakphum-calendar

CMD ["/bin/bash"]
