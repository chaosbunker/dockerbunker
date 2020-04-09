# What is dockerbunker

`dockerbunker` is a tool that helps configure, deploy and manage dockerized web-applications or static sites behind an nginx reverse proxy. Apps can easily be fully backed up or restored from a previous backup. The only requirement is docker.

Have a look at [this asciicast](https://asciinema.org/a/PGkj249ZRCtYKKSmpgqymBWmh) to see `dockerbunker`in action.

Index:
* [Services](#services)
* [Other build in Services](#other_build_in_services)
* [Upgrade Dockerbunker-v1 to -v2](#upgrade_dockerbunker_v1_to_v2)
* [Prerequisites](#prerequisites)
* [How to get started](#how_to_get_started)
* [Ddd custom services](#add_custom_services)
* [add custom static website](#add_custom_static_website)
* [add your external service](#add_your_external_service)
* [add your external SSL](#ssl)
* [Backup & Restore](#backup_restore)
* [Good to know](#good_to_know)
* [Why I made this](#why_i_made_this)


#### <span id="services">Services:</span>

| A - G |
|---|---|
|[Bitbucket](https://www.atlassian.com/software/bitbucket) | [&#9760;] some issue |
|[Commento](https://github.com/adtac/commento) | [&#9760;] some issue |
|[cryptpad](https://cryptpad.fr/) | **[&#10004;]** install works |
|[CS50 IDE](https://manual.cs50.net/ide/offline) | [&#9760;] some issue |
|[Dillinger](https://dillinger.io/) | **[&#10004;]** install works |
|[Drone CI](https://github.com/drone/drone) | **[&#10004;] works** | Continuous Delivery system |
|[Fathom Analytics](https://github.com/usefathom/fathom) | **[&#10004;]** install works |
|[Firefly III](https://github.com/firefly-iii/firefly-iii) | [&#9760;] some issue |
|[Firefox Sync Server](https://github.com/mozilla-services/syncserver) | **[&#10004;]** install works |
|[Ghost Blog](https://ghost.org/) | **[&#10004;]** install works |
|[GitBucket](https://github.com/gitbucket/gitbucket) | **[&#10004;]** install works |
|[Gitea](https://gitea.io/en-us/) | **[&#10004;] works** | Git Server |
|[Gitlab CE](https://gitlab.com/) | [&#9760;] some issue |
|[Gogs](https://gogs.io/) | [&#9760;] some issue |

| H - N |
|---|---|
|[Hastebin](https://hastebin.com/about.md) | **[&#10004;]** install works |
|[IPsec VPN Server](https://github.com/hwdsl2/docker-ipsec-vpn-server) | [&#9760;] some issue |
|[json-server](https://github.com/typicode/json-server) | [&#9760;] some issue |
|[Kanboard](https://kanboard.net/) | **[&#10004;]** install works |
|[KeeWeb](https://github.com/keeweb/keeweb) | **[&#10004;] works** | this is a static KeyPassX ProgressiveWebapp |
|[Koken](http://koken.me/) | **[&#10004;]** install works |
|[Mailcow Dockerized](https://github.com/mailcow/mailcow-dockerized) | [&#9760;] some issue |
|[Mailpile](https://www.mailpile.is/) | **[&#10004;]** install works |
|[Mastodon](https://github.com/tootsuite/mastodon) | [&#9760;] some issue |
|[Matomo Analytics](https://github.com/matomo-org/docker) | **[&#10004;]** install works |
|[Mozilla send](https://send.firefox.com/) | **[&#10004;] works** | Simple, private file sharing from the makers of Firefox |
|[Nextcloud](https://github.com/nextcloud/docker) | **[&#10004;] works** | self-hosted cloud-server|

| O - Z |
|---|---|
|[Open Project](https://www.openproject.org/) | [&#9760;] some issue |
|[Padlock Cloud](https://github.com/padlock/padlock-cloud) | [&#9760;] some issue |
|[Rocket.Chat](https://github.com/RocketChat/Rocket.Chat) | [&#9760;] some issue |
|[Seafile Pro (broken)](https://github.com/haiwen/seafile) | [&#9760;] some issue |
|[Searx](https://github.com/asciimoo/searx.git) | [&#9760;] some issue |
|[sFTP Server](https://github.com/atmoz/sftp) | [&#9760;] some issue |
|[Wekan](https://github.com/wekan/wekan) | **[&#10004;] works** | open source kanban |
|[Wordpress](https://wordpress.org/) | **[&#10004;]** install works |


#### <span id="other_build_in_services">Other build in Services</span>

| Service | Status | Description |
|---|---|--- |
|[proxy-pass](data/services/proxy-pass) | **[&#10004;] works** | Use Dockerbunker as reverse-proxy, to work with your external Service/Server |
|[static-sites](data/services/static-sites) | **[&#10004;] works** | use some static HTML sites (within build/service-name/web) |

**Fair warning:**
While all services appeared fully functional at the time I implemented them, I cannot guarantee that they still all are functional. Sometimes I just added something I was playing around with and hadn't tested every part of it. If something turns out to be not working, it often times broke because of changes that were made to the software and it most cases it's trivial to make it work again. I **marked bold** all the apps I am personally using with `dockerbunker`, as well as those that I recently tested and expect to work without issues. That being said, use this at your own risk. And if you do use `dockerbunker` and notice that something doesn't work, please file an issue .. or even better, submit a pull request. Contributions are welcome:)

## <span id="upgrade_dockerbunker_v1_to_v2">Upgrade Dockerbunker-v1 to -v2</span>

There are some big changes with the docker-v2 and ith wont be run without manually changes.

0. At first **Backup your dockerbunker sytem**

### Environment TODOs:

1. move all Environment-Files into ```/build``` folder, e.g. ```/build/conf```, ```/build/web```, ```/build/backup``` and ```/build/env```
2. update your environment Variables within ```build/env/dockerbunker.env``` (take a look at the default Variables within ```data/include/init.sh```)

### Service TODOs:

1. now, service entry-point (```service-name/ìnit.sh```) and service setup (```service-name/service.sh```) was splitted
2. edit your ```service-name/service.sh``` to match your old settings

## <span id="prerequisites">Prerequisites</span>

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

## <span id="how_to_get_started">How to get started</span>

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

### <span id="add_custom_services">Ddd custom services</span>

You can add some services by your own.

1. To do so, only copy another service which match your new service the best. copy ```/data/services/some-service``` and rename it to your needed service.
2. setup your service parameter wihtin ```service.sh```
3. add oder update your ```docker run``` commands if needed for your service
4. update the nginx-reverse-proxy settings within ```nginx/service.conf```


When destroying a service everything related to the service will be removed. Only Let's Encrypt certificates will be retained.

### <span id="add_custom_static_website">add custom static website</span>

1. start the ```static-sites``` service
2. add your specific domain and the other parameter
3. after that, dockerbunker installs your static-site to ```/build/web/service-name/index.html```
4. now, you have to add your staic-site files into ```/build/web/service-name/```
5. thats it, your static site should work

### <span id="add_your_external_service">add your external service</span>

to add your external service, and use it via dockerbunker as a reverse-proxy.

1. copy/paste nginx-default-proxy-pass.config ```proxy-pass/nginx/service.conf``` and edit to work with your service
2. start the ```proxy-pass``` service
3. add your specific domain and the other parameter
4. run the setup process
5. thats it, your reverse proxy should work


### <span id="ssl">add your external SSL</span>

When configuring a service, a self-signed certificate is generated and stored in `build/conf/nginx/ssl/${SERVICE_HOSTNAME}`. Please move your own trusted certificate and key in that directory as `cert.pem` and `key.pem` after configuration of the service is complete.

If you choose to use [Let's Encrypt](https://letsencrypt.org/) during setup, certificates will be automatically obtained via a Certbot container. Let's Encrypt data is stored in `build/conf/nginx/ssl/letsencrypt`.

It is possible to add additional domains to the certificate before obtaining the certificate and these domains will also automatically be added to the corresponding nginx configuration.

#### <span id="backup_restore">Backup & Restore</span>

When backing up a service, a timestamped directory will be created in `build/backup/${SERVICE_NAME}`. The following things will get backed up into (or restored from) that directory:

- All volumes (will be compressed)
- nginx configuration if service is accessible via web (from build/conf/nginx/conf.d/${SERVICE_DOMAIN})
- other user-specific configuration files (from build/conf/${SERVICE_NAME})
- environment file(s) (from build/env/${SERVICE_NAME}*)
- ssl certificate" (from build/conf/nginx/ssl/${SERVICE_DOMAIN} and, if applicable build/conf/nginx/ssl/letsencrypt)

#### <span id="good_to_know">Good to know</span>

All credentials that are set by the user or that are automatically generated are stored in build/env/${SERVICE_NAME}.env.

Please refer to the documentation of each web-app (regarding default credentials, configuration etc.)

#### <span id="why_i_made_this">Why I made this</span>

I know that it is not really ideal and recommended to do something like this with shell scripts. `dockerbunker` is an idea that went a bit out of control. It was inspired by [@DFabric's](https://github.com/DFabric/) [DPlatform-DockerShip](https://github.com/DFabric/DPlatform-DockerShip). You can read more about why I made dockerbunker [here](https://chaosbunker.com/post/dockerbunker) (tl;dr: I enjoyed the process)

**Important: Please make sure you agree with the license(s) of the open source software you are installing via dockerbunker. Any part of dockerbunker itself is released under the MIT License.**
