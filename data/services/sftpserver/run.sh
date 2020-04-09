#!/usr/bin/env bash

chmod 400 /etc/ssh/ssh_host_ed25519_key
chmod 400 /etc/ssh/ssh_host_rsa_key

cd /home
for user in *; do
	[[ ! -d /home/${user}/upload ]] && mkdir /home/${user}/upload
	chown -R ${user}:users ${user}/*
done
