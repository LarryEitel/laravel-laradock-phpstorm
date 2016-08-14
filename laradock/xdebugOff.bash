#! /bin/bash

echo "STOP xdebug"

REMOVE_EXTENSION_CMD='rm -f /usr/local/etc/php/conf.d/xdebug_extension_only.ini'

# If running on Windows, need to prepend with winpty :(
if [[ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]]; then
    # This is the equivalent of:
    # winpty docker exec -it laradock_php-fpm_1 bash -c 'bla bla bla'
    # Thanks to @michaelarnauts at https://github.com/docker/compose/issues/593
    winpty docker exec -it $(docker-compose ps | grep php-fpm | cut -d" " -f 1) \
        bash -c "${REMOVE_EXTENSION_CMD}"
    docker-compose restart php-fpm
    winpty docker exec -it $(docker-compose ps | grep php-fpm | cut -d" " -f 1) \
        bash -c 'php -v'
else
    docker exec -it $(docker-compose ps | grep php-fpm | cut -d" " -f 1) \
        bash -c "${REMOVE_EXTENSION_CMD}"
    docker-compose restart php-fpm
    docker exec -it $(docker-compose ps | grep php-fpm | cut -d" " -f 1) \
        bash -c 'php -v'
fi
