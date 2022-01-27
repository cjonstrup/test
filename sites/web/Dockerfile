FROM registry.gitlab.com/demo/php-app/base AS site

LABEL "website.name"="web"

# Copy project files to the container and set workdir
#COPY ./stack/sites/default/project /project
#COPY ./stack/sites/default/entrypoint-web.sh /entrypoint-web.sh


ENTRYPOINT ["/entrypoint-web.sh"]
