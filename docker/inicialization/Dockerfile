FROM docker:27.3.1-cli-alpine3.20

COPY ./docker/inicialization/init.sh /usr/src/init.sh

RUN chmod +x /usr/src/init.sh

ENTRYPOINT ["/usr/src/init.sh"]