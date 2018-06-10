#!/bin/sh

set -xe

echo '
{
  "host": "0.0.0.0",
  "port": 7777,
  "keyLength": 6,
  "maxLength": 400000,
  "staticMaxAge": 86400,
  "recompressStaticAssets": true,
  "logging": [
    {
      "level": "verbose",
      "type": "Console",
      "colorize": true
    }
  ],
  "keyGenerator": {
    "type": "random"
  },
  "rateLimits": {
    "categories": {
      "normal": {
        "totalRequests": 500,
        "every": 60000
      }
    }
  },
  "documents": {
    "about": "/hastebin/about.md",
    "haste": "/hastebin/haste.py"
  },
' > config.js

if [ "$STORAGE_TYPE" = "file" ]
then
    echo '
        "storage": {
          "path": "/hastebin/data",
          "type": "file"
        }
    ' >> config.js
fi

if [ "$STORAGE_TYPE" = "redis" ]
then
    npm install redis
    echo '
      "storage": {
        "type": "redis",
        "host": "'"${REDIS_HOST}"'",
        "port": 6379,
        "db": 2,
        "expire": 2592000
      }
    ' >> config.js
fi

echo '}' >> config.js

chown "$UID:$GID" -R /hastebin
su-exec "$UID:$GID" npm start
