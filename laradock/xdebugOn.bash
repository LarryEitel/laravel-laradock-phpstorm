#! /bin/bash

# NOTE: At the moment, this has only been confirmed to work PHP 7

echo "Start xdebug"


# Grab full name of php-fpm container
PHP_FPM_CONTAINER=$(docker-compose ps | grep php-fpm | cut -d" " -f 1)


# Copy important xdebug remote settings from workspace container to php-fpm
# And uncomment line with xdebug extension, thus enabling it
ON_CMD="cp \
            /var/www/laravel/laradock/workspace/xdebug_settings_only.ini \
            /usr/local/etc/php/conf.d \
        && sed \
            -i 's/^;zend_extension=/zend_extension=/g' \
            /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"


# If running on Windows, need to prepend with winpty :(
if [[ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]]; then
    winpty docker exec -it $PHP_FPM_CONTAINER bash -c "${ON_CMD}"
    docker restart $PHP_FPM_CONTAINER
    winpty docker exec -it $PHP_FPM_CONTAINER bash -c 'php -v'

else
    docker exec -it $PHP_FPM_CONTAINER bash -c "${ON_CMD}"
    docker restart $PHP_FPM_CONTAINER
    docker exec -it $PHP_FPM_CONTAINER bash -c 'php -v'
fi
