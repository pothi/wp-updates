#!/bin/bash

# script to monitor changes and optionally update the installed WP plugins

# version 1.0

#--- Variables ---#

# the script assumes your sites are stored like ~/sites/example.com/public, ~/sites/example.net/public, ~/sites/example.org/public and so on.
# if you have a different pattern, such as ~/app/example.com, please change the following to fit the server environment!
SITES_PATH=${HOME}/sites

# if WP is in a sub-directory, please leave this empty!
PUBLIC_DIR=public

#--- You need not edit below this line ---#

logfile=${HOME}/log/wp-cli.log
exec > >(tee -a ${logfile} )
exec 2> >(tee -a ${logfile} >&2)

declare -r wp_cli=/usr/local/bin/wp
declare -r script_name=$(basename "$0")
declare -r timestamp=$(date +%F_%H-%M-%S)
declare -r datestamp=$(date +%F)
echo $timestamp
declare -r plugins_status_log=${HOME}/log/wp-plugin-status-${datestamp}.log
declare -r plugins_status_log_after_update=${HOME}/log/wp-plugin-status-after-update-${datestamp}.log
declare -r plugins_update_log=${HOME}/log/plugin-update-${datestamp}.log
update_plugins=false

# usage info
show_help() {
cat << EOF
Usage: ${0##*/} [-h] [-u] example.com
Check the status of installed WordPress plugins for the site example.com using wp-cli.
Log the result in ${HOME}/log/wp-plugin-status-*.log where * denotes the datestamp.

    -h  display this help and exit
    -u  try to update the installed plugins and log the result in ${HOME}/log/wp-plugin-status-after-update-*.log
EOF
}

# check if log directory exists
if [ ! -d "${HOME}/log" ] && [ "$(mkdir -p ${HOME}/log)" ]; then
    echo 'Log directory not found. The script does not have the permission to create it either!'
    echo "Please create it manually at $HOME/log and then re-run this script."
    exit 1
fi

# http://mywiki.wooledge.org/BashFAQ/035
# http://wiki.bash-hackers.org/howto/getopts_tutorial
OPTIND=1
while getopts hu opt ; do
    case $opt in
        h)
            show_help
            exit 0
            ;;
        u)
            update_plugins=true
            ;;
        *)
            show_help >&2
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))"

if [ -z "$1" ]; then
    show_help
    exit 1
else
    DOMAIN=$1
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

$wp_cli --no-color --quiet --path=${WP_PATH} plugin status > $plugins_status_log

# remove the line "n installed plugins"
# remove the line starts with Legend
# remove the empty line/s
# remove any leading spaces on each line
sed -e '/installed plugins/ d' -e '/^Legend/ d' -e '/^$/ d' -e 's/^[[:space:]]\+//g' -i $plugins_status_log

if $update_plugins ; then
    echo 'Updating plugins...'
    $wp_cli --no-color --quiet --path=${WP_PATH} plugin update --all > $plugins_update_log
    $wp_cli --no-color --quiet --path=${WP_PATH} plugin status > $plugins_status_log_after_update
    echo 'done.'
fi

if [ "$?" != "0" ]; then
	echo 'Error: Something did not go well. Please check the log at '$logfile
	exit 1
fi

echo "The script '$script_name' successfully run for '$DOMAIN'!"
