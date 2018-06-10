### Thanks to [https://github.com/nrobinaubertin/dockerfiles/tree/master/send](nrobinaubertin) for this Dockerfile. Original README below

Send
====
*Simple, lightweight and secure Send container based on Alpine Linux*

![send](send.jpg)

### What is send ?
[Send](https://send.firefox.com/) is a file sharing system by Mozilla that allows you to send files through a safe, private, and encrypted link that automatically expires to ensure your stuff does not remain online forever. You can find the official repository [here](https://github.com/mozilla/send).

### Goal of this container
Propose a lightweight and secure container that is easy to setup.

### Features
- Based on Alpine Linux.
- No Root processes, as secure as possible.

### Run-time variables
- **UID**: (Optional) The UID executing the server
- **GID**: (Optional) The GID executing the server

### Ports
- **1443**

### Setup
Example command to build this image:
```
docker build -t send .
```
Example command to run this container:
```
docker run --init -d -p 1443:1443 --name send send
```
