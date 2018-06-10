FROM phusion/baseimage:0.9.22

MAINTAINER Dennis Rodewyk <ufo@chaosbunker.com>

ENV SEAFILE_VERSION 6.2.13
EXPOSE 80

VOLUME /seafile
WORKDIR /seafile

# Required packages for pro edition
RUN apt-get update && apt-get install -y \
  openjdk-8-jre poppler-utils libpython2.7 python-pip \
  python-setuptools python-imaging python-mysqldb python-memcache python-ldap \
  python-urllib3 wget nginx \
  libreoffice libreoffice-script-provider-python fonts-vlgothic ttf-wqy-microhei ttf-wqy-zenhei xfonts-wqy && pip install boto

# Download seafile binary
RUN wget "https://download.seafile.com/d/6e5297246c/files/?p=/pro/seafile-pro-server_${SEAFILE_VERSION}_x86-64.tar.gz&dl=1" -O "/seafile-pro-server_${SEAFILE_VERSION}_x86-64.tar.gz"

# Install Seafile service.
ADD service/seafile/run.sh /etc/service/seafile/run
ADD service/seafile/stop.sh /etc/service/seafile/stop

# Install Seahub service.
ADD service/seahub/run.sh /etc/service/seahub/run
ADD service/seahub/stop.sh /etc/service/seahub/stop

# Install Ngninx service
ADD service/nginx/run.sh /etc/service/nginx/run

# Add custom configuration
COPY config/seafevents.conf /seafevents.conf

# Configure nginx
COPY config/seafile.conf /etc/nginx/sites-available/seafile.conf
RUN ln -s /etc/nginx/sites-available/seafile.conf /etc/nginx/sites-enabled/seafile.conf && \
	rm /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD bin/setup.sh /usr/local/sbin/setup
ADD bin/upgrade.sh /usr/local/sbin/upgrade

# Set permissions
RUN chmod +x /usr/local/sbin/setup && \
	chmod +x /usr/local/sbin/upgrade && \
	chmod +x /etc/service/seafile/* && \
	chmod +x /etc/service/seahub/* && \
	chmod +x /etc/service/nginx/*

CMD /sbin/my_init
