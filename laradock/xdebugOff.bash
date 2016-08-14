#! /bin/bash

# NOTE: At the moment, this has only been confirmed to work PHP 7

echo "STOP xdebug"


# Grab full name of php-fpm container
PHP_FPM_CONTAINER=$(docker-compose ps | grep php-fpm | cut -d" " -f 1)


# Comment out xdebug extension line
OFF_CMD="sed -i 's/^zend_extension=/;zend_extension=/g' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"


# If running on Windows, need to prepend with winpty :(
if [[ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]]; then
    # This is the equivalent of:
    # winpty docker exec -it laradock_php-fpm_1 bash -c 'bla bla bla'
    # Thanks to @michaelarnauts at https://github.com/docker/compose/issues/593
    winpty docker exec -it $PHP_FPM_CONTAINER bash -c "${OFF_CMD}"
    docker restart $PHP_FPM_CONTAINER
    #docker-compose restart php-fpm
    winpty docker exec -it $PHP_FPM_CONTAINER bash -c 'php -v'

else
    docker exec -it $PHP_FPM_CONTAINER bash -c "${OFF_CMD}"
    # docker-compose restart php-fpm
    docker restart $PHP_FPM_CONTAINER
    docker exec -it $PHP_FPM_CONTAINER bash -c 'php -v'
fi
