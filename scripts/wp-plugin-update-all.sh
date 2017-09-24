#!/bin/bash

# script to update WP plugins

#--- Variables ---#

# the script assumes your sites are stored like ~/sites/example.com/public, ~/sites/example.net/public, ~/sites/example.org/public and so on.
# if you have a different pattern, such as ~/app/example.com, please change the following to fit the server environment!
SITES_PATH=${HOME}/sites

# if WP is in a sub-directory, please leave this empty!
PUBLIC_DIR=public

# You may hard-code the domain name
DOMAIN=

#--- Do NOT Edit below this line ---#

logfile=${HOME}/log/wp-cli.log
exec > >(tee -a ${logfile} )
exec 2> >(tee -a ${logfile} >&2)

declare -r wp_cli=$(which wp)
declare -r script_name=$(basename "$0")
declare -r timestamp=$(date +%F_%H-%M-%S)
declare -r datestamp=$(date +%F)
echo $timestamp

# check if log directory exists
if [ ! -d "${HOME}/log" ] && [ "$(mkdir -p ${HOME}/log)" ]; then
    echo 'Log directory not found. The script does not have the permission to create it either!'
    echo "Please create it manually at $HOME/log and then re-run this script."
    exit 1
fi

if [ -z "$DOMAIN" ]; then
    if [ -z "$1" ]; then
		echo "Usage $script_name example.com"
		exit 1
    else
        DOMAIN=$1
    fi
fi

WP_PATH=${SITES_PATH}/$DOMAIN/${PUBLIC_DIR}
if [ ! -d "$WP_PATH" ]; then
	echo 'Error: WordPress installation is not found at '$WP_PATH
	exit 1
fi

if [ ! -f "$wp_cli" ]; then
	echo 'Error: wp-cli is not found'
	exit 1
fi

$wp_cli --no-color --quiet --path=${WP_PATH} plugin status > ${HOME}/log/plugins-status-before-plugins-update-${datestamp}.log
$wp_cli --no-color --quiet --path=${WP_PATH} plugin update --all > ${HOME}/log/plugins-update-${datestamp}.log
$wp_cli --no-color --quiet --path=${WP_PATH} plugin status > ${HOME}/log/plugins-status-after-plugins-update-${datestamp}.log
if [ "$?" != "0" ]; then
	echo 'Error: Something did not go well. Please check the log at '$logfile
	exit 1
fi

echo "The script '$script_name' successfully run for '$DOMAIN'!"
