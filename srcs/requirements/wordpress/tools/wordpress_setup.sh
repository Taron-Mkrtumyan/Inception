#!/bin/bash
set -eu

if [ ! -x /usr/local/bin/wp ]; then
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod	+x wp-cli.phar
	mv		wp-cli.phar /usr/local/bin/wp
fi

until mariadb-admin ping -h mariadb -u"${SQL_USER}" -p"${SQL_PASSWORD}" --silent; do
	sleep 2
done

if [ ! -f /var/www/html/wp-config.php ]; then
	wp core download	--allow-root --force

	wp config create	--allow-root \
						--dbname=${SQL_DATABASE} \
						--dbuser=${SQL_USER} \
						--dbpass=${SQL_PASSWORD} \
						--dbhost=mariadb

	wp core install		--allow-root \
						--url="https://${DOMAIN_NAME}" \
						--title=${SITE_TITLE} \
						--admin_user=${ADMIN_USER} \
						--admin_password=${ADMIN_PASSWORD} \
						--admin_email=${ADMIN_EMAIL}
	wp user create		--allow-root \
						${USER_NAME} ${USER_EMAIL} \
						--user_pass=${USER_PASSWORD} \
						--role=author
fi

mkdir -p /run/php

exec "$@"