#! /bin/bash

echo "Start xdebug"
winpty docker exec -it laradock_php-fpm_1 \
    bash -c 'ls /usr/local/etc/php/conf.d'

winpty docker exec -it laradock_php-fpm_1 \
    bash -c 'cp /var/www/laravel/laradock/workspace/xdebug_*.ini /usr/local/etc/php/conf.d'

docker stop laradock_php-fpm_1
docker start laradock_php-fpm_1
winpty docker exec -it laradock_php-fpm_1 bash -c 'php -v'
