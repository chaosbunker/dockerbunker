#!/bin/sh

export NODE_ENV=production
chown -R "${UID}:${GID}" /send /etc/s6.d
su-exec "${UID}:${GID}" /bin/s6-svscan /etc/s6.d
