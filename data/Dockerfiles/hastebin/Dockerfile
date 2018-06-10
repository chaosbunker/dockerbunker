FROM node:8.1-alpine

ENV REDIS_HOST=0.0.0.0
ENV STORAGE_TYPE=file 
ENV UID=791 GID=791

EXPOSE 7777

COPY run.sh /usr/local/bin/run.sh
COPY about.md /hastebin/about.md
COPY haste.py /hastebin/haste.py

WORKDIR /hastebin

RUN set -xe \
    && apk add -U --no-cache --virtual .build-deps zip unzip ca-certificates openssl \
    && apk add -U --no-cache su-exec busybox \
    && wget https://github.com/seejohnrun/haste-server/archive/master.zip \
    && unzip master.zip \
    && find haste-server-master -mindepth 1 -maxdepth 1 -print0 | xargs -0 -i mv {} /hastebin \
    && rmdir haste-server-master \
    && rm master.zip \
    && npm install \
    && chmod +x -R /usr/local/bin/run.sh \
    && apk del .build-deps

CMD ["run.sh"]
