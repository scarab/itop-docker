#!/bin/bash -x

if [ "$BUILD_ARGUMENT_ENV" == "development" ]; then
    install-php-extensions xdebug
    mv $ARTIFACTS_TMP/xdebug.ini $PHP_INI_DIR/conf.d/xdebug.ini
fi
