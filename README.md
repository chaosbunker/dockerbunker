# What is dockerbunker

`dockerbunker` is a tool that helps configure, deploy and manage dockerized web-applications or static sites behind an nginx reverse proxy. Apps can easily be fully backed up or restored from a previous backup. The only requirement is docker.

Have a look at [this asciicast](https://asciinema.org/a/PGkj249ZRCtYKKSmpgqymBWmh) to see `dockerbunker`in action.

#### Services which work:

| Service | Status |
|---|---|
|[Drone CI](https://github.com/drone/drone)| |
|[Firefox Sync Server](https://github.com/mozilla-services/syncserver)| |
|[Gitea](https://gitea.io/en-us/)| [&#10004;] i use it live |
|[Gitlab CE](https://gitlab.com/)| |
|[Gogs](https://gogs.io/)| |
|[Mozilla send](https://send.firefox.com/)| [&#10004;] i use it live |
|[Nextcloud](https://github.com/nextcloud/docker)| [&#10004;] i use it live |
|[Rocket.Chat](https://github.com/RocketChat/Rocket.Chat)| |
|[Wekan](https://github.com/wekan/wekan)| |


**Fair warning:** While all services appeared fully functional at the time I implemented them, I cannot guarantee that they still all are functional. Sometimes I just added something I was playing around with and hadn't tested every part of it. If something turns out to be not working, it often times broke because of changes that were made to the software and it most cases it's trivial to make it work again. I **marked bold** all the apps I am personally using with `dockerbunker`, as well as those that I recently tested and expect to work without issues. That being said, use this at your own risk. And if you do use `dockerbunker` and notice that something doesn't work, please file an issue .. or even better, submit a pull request. Contributions are welcome:)

## Prerequisites

- Docker
- Bash 4+


	On macOS via [homebrew](https://brew.sh)
	- Bash 4+ -> `brew install bash`
	- GNU grep -> `brew install grep`
	- GNU sed -> `brew install gnu-sed`

		```
		ln -sv /usr/local/bin/ggrep /usr/local/bin/grep
		ln -sv /usr/local/bin/gsed /usr/local/bin/sed
		```

		Make sure `/usr/local/bin`is added to your PATH! If it's not:

		`echo 'PATH="/usr/local/bin:$PATH"' >> ~/.bash_profile`

## How to get started:

1. Get docker

    - Most systems can install Docker by running `wget -qO- https://get.docker.com/ | sh`

3. Clone the master branch of this repository and run `./dockerbunker.sh`

    - `git clone https://github.com/chaosbunker/dockerbunker.git && cd dockerbunker`
	- `./dockerbunker.sh`

4. Select a service and configure it (Set domain, etc..)

5. Set up the service. This will
	- Create an internal network if necessary
	- Create volumes
	- Pull images
	- Run containers
	- Obtain certificate from Let's Encrypt (if chosen during config)

That's it.

Now when selecting the same service again in the `dockerbunker` menu, there will be more options depending on the current state of the service. For example:
```
Nextcloud
1) Reconfigure service
2) Reinstall service
3) Obtain Let's Encrypt certificate (<-- only visible if using self-signed cert)
4) Restart container(s)
5) Stop container(s) (<- only visible when containers are running, otherwise offers "Start Containers"
6) Backup Service
7) Restore Service (<- only visible if backup(s) for service are found)
8) Upgrade Image(s)
9) Destroy "Nextcloud"
```

When destroying a service everything related to the service will be removed. Only Let's Encrypt certificates will be retained.

### SSL

When configuring a service, a self-signed certificate is generated and stored in `data/conf/nginx/ssl/${SERVICE_HOSTNAME}`. Please move your own trusted certificate and key in that directory as `cert.pem` and `key.pem` after configuration of the service is complete.

If you choose to use [Let's Encrypt](https://letsencrypt.org/) during setup, certificates will be automatically obtained via a Certbot container. Let's Encrypt data is stored in `data/conf/nginx/ssl/letsencrypt`.

It is possible to add additional domains to the certificate before obtaining the certificate and these domains will also automatically be added to the corresponding nginx configuration.

#### Backup & Restore

When backing up a service, a timestamped directory will be created in `data/backup/${SERVICE_NAME}`. The following things will get backed up into (or restored from) that directory:

- All volumes (will be compressed)
- nginx configuration if service is accessible via web (from data/conf/nginx/conf.d/${SERVICE_DOMAIN})
- other user-specific configuration files (from data/conf/${SERVICE_NAME})
- environment file(s) (from data/env/${SERVICE_NAME}*)
- ssl certificate" (from data/conf/nginx/ssl/${SERVICE_DOMAIN} and, if applicable data/conf/nginx/ssl/letsencrypt)

#### Good to know:
All credentials that are set by the user or that are automatically generated are stored in data/env/${SERVICE_NAME}.env.

Please refer to the documentation of each web-app (regarding default credentials, configuration etc.)

#### Why I made this

I know that it is not really ideal and recommended to do something like this with shell scripts. `dockerbunker` is an idea that went a bit out of control. It was inspired by [@DFabric's](https://github.com/DFabric/) [DPlatform-DockerShip](https://github.com/DFabric/DPlatform-DockerShip). You can read more about why I made dockerbunker [here](https://chaosbunker.com/post/dockerbunker) (tl;dr: I enjoyed the process)

**Important: Please make sure you agree with the license(s) of the open source software you are installing via dockerbunker. Any part of dockerbunker itself is released under the MIT License.**
