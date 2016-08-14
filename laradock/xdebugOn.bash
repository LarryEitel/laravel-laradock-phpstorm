#! /bin/bash

echo "Start xdebug"


COPY_INI_FILE_CMD='cp /var/www/laravel/laradock/workspace/xdebug_*.ini /usr/local/etc/php/conf.d'


# If running on Windows, need to prepend with winpty :(
if [[ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]]; then
    winpty docker exec -it $(docker-compose ps | grep php-fpm | cut -d" " -f 1) \
        bash -c "${COPY_INI_FILE_CMD}"
    docker-compose restart php-fpm
    winpty docker exec -it $(docker-compose ps | grep php-fpm | cut -d" " -f 1) \
        bash -c 'php -v'
else
    docker exec -it $(docker-compose ps | grep php-fpm | cut -d" " -f 1) \
        bash -c "${COPY_INI_FILE_CMD}"
    docker-compose restart php-fpm
    docker exec -it $(docker-compose ps | grep php-fpm | cut -d" " -f 1) \
        bash -c 'php -v'
fi
