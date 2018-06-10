#!/bin/bash

cd /seafile

echo "Checking if Seafile is installed ..."
if [ ! -d "/seafile/seafile-server-latest" ]; then
	echo "[FAILED] Seafile is not installed!"
	exit 0
fi

# Get version based on the seafile-server-latest symbolic link that is pointing to the current installation.
CURRENT_VERSION=$(ls -lah | grep 'seafile-server-latest' | awk -F"seafile-pro-server-" '{print $2}')
NEW_VERSION=$1

if [ "$CURRENT_VERSION" == "$NEW_VERSION" ]; then
	echo "[FAILED] You already have the most recent version installed"
	exit 0
else
	echo "Downloading seafile-pro-server_${NEW_VERSION}_x86-64.tar.gz"
	if [ ! -f /seafile-pro-server_${NEW_VERSION}_x86-64.tar.gz ];then
		wget "https://download.seafile.com/d/6e5297246c/files/?p=/pro/seafile-pro-server_${NEW_VERSION}_x86-64.tar.gz&dl=1" -O "/seafile-pro-server_${NEW_VERSION}_x86-64.tar.gz" 2>/dev/null
	fi
fi

echo "Extracting server binary ..."
tar -xzf "/seafile-pro-server_${NEW_VERSION}_x86-64.tar.gz" 2>/dev/null
if [[ $? != 0 ]];then
	echo "Could not extract server binary. Are you sure $NEW_VERSION is a valid version number?"
	rm /seafile-pro-server_${NEW_VERSION}_x86-64.tar.gz
	exit 1
fi
mv "/seafile-pro-server_${NEW_VERSION}_x86-64.tar.gz" installed/

cd "/seafile/seafile-pro-server-${NEW_VERSION}"

# First we need to check if it's a maintenance update, since the process is different from a major/minor version upgrade
CURRENT_MAJOR_VERSION=$(echo $CURRENT_VERSION | awk -F"." '{print $1}')
CURRENT_MINOR_VERSION=$(echo $CURRENT_VERSION | awk -F"." '{print $2}')
CURRENT_MAINTENANCE_VERSION=$(echo $CURRENT_VERSION | awk -F"." '{print $3}')

NEW_MAJOR_VERSION=$(echo $NEW_VERSION | awk -F"." '{print $1}')
NEW_MINOR_VERSION=$(echo $NEW_VERSION | awk -F"." '{print $2}')
NEW_MAINTENANCE_VERSION=$(echo $NEW_VERSION | awk -F"." '{print $3}')

if [ "$CURRENT_MAJOR_VERSION" == "$NEW_MAJOR_VERSION" ] && [ "$CURRENT_MINOR_VERSION" == "$NEW_MINOR_VERSION" ]; then
  # Alright, this is only a maintenance update.
  echo "Performing maintenance update ..."
  ./upgrade/minor-upgrade.sh
  cd /seafile
  rm -rf "/seafile/seafile-pro-server-${CURRENT_VERSION}"
else
  # Big version jump (e.g. 6.1.x to 6.2.x)
  for file in ./upgrade/upgrade_*.sh
  do
    UPGRADE_FROM=$(echo "$file" | awk -F"_" '{print $2}')
    UPGRADE_TO=$(echo "$file" | awk -F"_" '{print $3}' | sed 's/\.sh//g')

    if [ "$UPGRADE_FROM" == "$CURRENT_MAJOR_VERSION.$CURRENT_MINOR_VERSION" ]; then
      echo "Upgrading from $UPGRADE_FROM to $UPGRADE_TO ..."
      $file
      CURRENT_MAJOR_VERSION=$(echo $UPGRADE_TO | awk -F"." '{print $1}')
      CURRENT_MINOR_VERSION=$(echo $UPGRADE_TO | awk -F"." '{print $2}')
    fi
  done
fi

echo "All done! Bye."