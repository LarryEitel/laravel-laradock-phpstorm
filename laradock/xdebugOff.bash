#! /bin/bash

echo "STOP xdebug"
winpty docker exec -it laradock_php-fpm_1 \
    bash -c 'rm -f /usr/local/etc/php/conf.d/xdebug_extension_only.ini'

docker stop laradock_php-fpm_1
docker start laradock_php-fpm_1
winpty docker exec -it laradock_php-fpm_1 bash -c 'php -v'
