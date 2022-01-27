#!/usr/bin/env sh

# Make sure all environment variables are set correctly for cron
printenv | grep -v "no_proxy" >> /etc/environment

# Start nginx services
php-fpm -R
nginx

#test
# Start caddy
#hest run --config /project/Caddyfile

# Nice way of keeping container alive while also providing logs to docker
echo "cron.log created" > /var/log/cron.log

tail -F /usr/local/var/log/php-fpm.log -F /project/storage/logs/laravel.log -F /var/log/cron.log
