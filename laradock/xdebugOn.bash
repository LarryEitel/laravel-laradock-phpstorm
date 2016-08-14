#! /bin/bash

echo "Start xdebug"


COPY_INI_FILE_CMD='cp /var/www/laravel/laradock/workspace/xdebug_*.ini /usr/local/etc/php/conf.d'

# Grab full name of php-fpm container
PHP_FPM_CONTAINER=$(docker-compose ps | grep php-fpm | cut -d" " -f 1)

# If running on Windows, need to prepend with winpty :(
if [[ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]]; then
    winpty docker exec -it $PHP_FPM_CONTAINER bash -c "${COPY_INI_FILE_CMD}"
    docker restart $PHP_FPM_CONTAINER
    winpty docker exec -it $PHP_FPM_CONTAINER bash -c 'php -v'
else
    docker exec -it $PHP_FPM_CONTAINER bash -c "${COPY_INI_FILE_CMD}"
    docker restart $PHP_FPM_CONTAINER
    docker exec -it $PHP_FPM_CONTAINER bash -c 'php -v'
fi
