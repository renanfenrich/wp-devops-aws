#!/bin/ash

set -e

touch .env
envsubst < .env.example > .env

exec php-fpm
