FROM	debian:bookworm

RUN		apt-get update && apt-get install -y --no-install-recommends \
		curl \
		ca-certificates \
		php8.2 \
		php8.2-fpm \
		php8.2-mysql \
		php8.2-xml \
		php8.2-mbstring \
		php8.2-curl \
		php8.2-zip \
		php8.2-gd \
		php8.2-intl \
		php8.2-bcmath \
		php8.2-soap \
		php8.2-imagick \
		php8.2-redis \
		php8.2-xdebug \
		mariadb-client \
		&& apt-get clean \
		&& rm -rf /var/lib/apt/lists/*

COPY confs/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/wordpress_setup.sh /usr/local/bin/wordpress_setup.sh

RUN chmod +x /usr/local/bin/wordpress_setup.sh

WORKDIR /var/www/html

EXPOSE	9000

ENTRYPOINT	["/usr/local/bin/wordpress_setup.sh"]
CMD 		["php-fpm8.2", "-F"]