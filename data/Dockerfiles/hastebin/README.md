### Thanks to [https://github.com/nrobinaubertin/dockerfiles/tree/master/hastebin](nrobinaubertin) for this Dockerfile. Original README below

Hastebin
========
*Simple, lightweight and secure Hastebin container based on Alpine Linux*

![hastebin](hastebin.png)

### What is hastebin ?
[hastebin](https://hastebin.com/about.md) is the prettiest, easiest to use pastebin ever made. It is used to share text and can be used from the command line with the hastebin-client. You can find the server repo [here](https://github.com/seejohnrun/haste-server).

### Goal of this container
Propose a lightweight and secure container that is easy to setup.

### Features
- Based on Alpine Linux.
- No Root processes, as secure as possible.
- You can choose your storage type

### Run-time variables
- **STORAGE_TYPE**: (Optional) Type of storage ("file" or "redis")
- **REDIS_HOST**: (Optional) The ip of the redis db
- **UID**: (Optional) The UID executing the server
- **GID**: (Optional) The GID executing the server

### Ports
- **7777**

### Setup
Build this image:
```
docker build -t hastebin .
```
Now, you have two choices:

**1) Using internal file storage**  
This is the easyiest to set up. You just need to run:
```
docker run -d --name hastebin hastebin
```

**2) Using redis as storage**  
This will allow you to backup your data.
You need redis to store the data of this hastebin container:
```
docker run -d --name hastebin-redis redis:alpine
```
You can check the ip address of the hastebin-redis container with:
```
docker network inspect bridge
```
Then you just have to start the container, linking it to the hastebin-redis instance:
```
docker run -d -e STORAGE_TYPE=redis -e REDIS_HOST=172.17.0.2 --name hastebin --init hastebin
```

### Bonus script
I've made a python 3 script to send/get and encrypt/decrypt snippets.  
You can find it [here](haste.py).
