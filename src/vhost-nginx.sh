#!/usr/bin/env bash

#
# Script to create virtual host for Nginx server
#
# @author   Raj KB <magepsycho@gmail.com>
# @website  http://www.magepsycho.com
# @version  0.1.0

# UnComment it if bash is lower than 4.x version
shopt -s extglob

################################################################################
# CORE FUNCTIONS - Do not edit
################################################################################

## Uncomment it for debugging purpose
###set -o errexit
#set -o pipefail
#set -o nounset
#set -o xtrace

#
# VARIABLES
#
_bold=$(tput bold)
_underline=$(tput sgr 0 1)
_reset=$(tput sgr0)

_purple=$(tput setaf 171)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_tan=$(tput setaf 3)
_blue=$(tput setaf 38)

#
# HEADERS & LOGGING
#
function _debug()
{
    if [[ "$DEBUG" = 1 ]]; then
        "$@"
    fi
}

function _header()
{
    printf '\n%s%s==========  %s  ==========%s\n' "$_bold" "$_purple" "$@" "$_reset"
}

function _arrow()
{
    printf '➜ %s\n' "$@"
}

function _success()
{
    printf '%s✔ %s%s\n' "$_green" "$@" "$_reset"
}

function _error() {
    printf '%s✖ %s%s\n' "$_red" "$@" "$_reset"
}

function _warning()
{
    printf '%s➜ %s%s\n' "$_tan" "$@" "$_reset"
}

function _underline()
{
    printf '%s%s%s%s\n' "$_underline" "$_bold" "$@" "$_reset"
}

function _bold()
{
    printf '%s%s%s\n' "$_bold" "$@" "$_reset"
}

function _note()
{
    printf '%s%s%sNote:%s %s%s%s\n' "$_underline" "$_bold" "$_blue" "$_reset" "$_blue" "$@" "$_reset"
}

function _die()
{
    _error "$@"
    exit 1
}

function _safeExit()
{
    exit 0
}

#
# UTILITY HELPER
#
function _seekConfirmation()
{
  printf '\n%s%s%s' "$_bold" "$@" "$_reset"
  read -p " (y/n) " -n 1
  printf '\n'
}

# Test whether the result of an 'ask' is a confirmation
function _isConfirmed()
{
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}


function _typeExists()
{
    if type "$1" >/dev/null; then
        return 0
    fi
    return 1
}

function _isOs()
{
    if [[ "${OSTYPE}" == $1* ]]; then
      return 0
    fi
    return 1
}

function _isOsDebian()
{
    if [[ -f /etc/debian_version ]]; then
        return 0
    else
        return 1
    fi
}

function _isOsRedHat()
{
    if [[ -f /etc/redhat-release ]]; then
        return 0
    else
        return 1
    fi
}

function _isOsMac()
{
    if [[ "$(uname -s)" = "Darwin" ]]; then
        return 0
    else
        return 1
    fi
}

function _checkRootUser()
{
    #if [ "$(id -u)" != "0" ]; then
    if [ "$(whoami)" != 'root' ]; then
        _die "You cannot run $0 as non-root user. Please use sudo $0"
    fi
}

function _printPoweredBy()
{
    local mp_ascii
    mp_ascii='
   __  ___              ___               __
  /  |/  /__ ____ ____ / _ \___ __ ______/ /  ___
 / /|_/ / _ `/ _ `/ -_) ___(_-</ // / __/ _ \/ _ \
/_/  /_/\_,_/\_, /\__/_/  /___/\_, /\__/_//_/\___/
            /___/             /___/
'
    cat <<EOF
${_green}
Powered By:
$mp_ascii

 >> Store: ${_reset}${_underline}${_blue}http://www.magepsycho.com${_reset}${_reset}${_green}
 >> Blog:  ${_reset}${_underline}${_blue}http://www.blog.magepsycho.com${_reset}${_reset}${_green}

################################################################
${_reset}
EOF
}

################################################################################
# SCRIPT FUNCTIONS
################################################################################
function _printUsage()
{
    echo -n "$(basename "$0") [OPTION]...

Nginx Virtual Host Creator
Version $VERSION

    Options:
        --domain                    Server Name
        --root-dir                  Application Root Directory. Default: current (pwd)
        --app                       Application Name (default, magento, magento2 & wordpress). Default: default
        -d, --debug                 Run command in debug mode
        -h, --help                  Display this help and exit

    Examples:
        $(basename "$0") --domain=... [--root-dir=...] [--app=...] [--debug]

"
    _printPoweredBy
    exit 1
}

function processArgs()
{
    # Parse Arguments
    for arg in "$@"
    do
        case $arg in
            --domain=*)
                VHOST_DOMAIN="${arg#*=}"
            ;;
            --root-dir=*)
                VHOST_ROOT_DIR="${arg#*=}"
            ;;
            --app=*)
                APP_TYPE="${arg#*=}"
            ;;
            --debug)
                DEBUG=1
                set -o xtrace
            ;;
            -h|--help)
                _printUsage
            ;;
            *)
                _printUsage
            ;;
        esac
    done

    validateArgs
    sanitizeArgs
}

function initDefaultArgs()
{
    VHOST_ROOT_DIR=$(pwd)
    NGINX_SITES_ENABLED_FILE=
    NGINX_SITES_AVAILABLE_FILE=
    APP_TYPE='default'

    if _isOsMac; then
        NGINX_SITES_ENABLED_DIR='/usr/local/etc/nginx/sites-enabled'
        NGINX_SITES_AVAILABLE_DIR='/usr/local/etc/nginx/sites-available'
    else
        NGINX_SITES_ENABLED_DIR='/etc/nginx/sites-enabled'
        NGINX_SITES_AVAILABLE_DIR='/etc/nginx/sites-available'
    fi
}

function validateArgs()
{
    ERROR_COUNT=0
    if [[ -z "$VHOST_DOMAIN" ]]; then
        _error "--domain parameter is missing."
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
    if [[ ! -d "$VHOST_ROOT_DIR" ]]; then
        _error "--root-dir parameter is not valid."
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
    if [[ ! -d "$NGINX_SITES_ENABLED_DIR" ]]; then
        _error "Nginx sites-enabled directory: ${NGINX_SITES_ENABLED_DIR} doesn't exist."
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
    if [[ ! -d "$NGINX_SITES_AVAILABLE_DIR" ]]; then
        _error "Nginx sites-available directory: ${NGINX_SITES_AVAILABLE_DIR} doesn't exist."
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
    if [[ -f "${NGINX_SITES_AVAILABLE_DIR}/${VHOST_DOMAIN}.conf" ]]; then
        _error "Vhost file already exists: ${NGINX_SITES_AVAILABLE_DIR}/${VHOST_DOMAIN}.conf."
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    [[ "$ERROR_COUNT" -gt 0 ]] && exit 1
}

function sanitizeArgs()
{
    # remove trailing /
    if [[ ! -z "$VHOST_ROOT_DIR" ]]; then
        VHOST_ROOT_DIR="${VHOST_ROOT_DIR%/}"
    fi
    if [[ ! -z "$VHOST_DOMAIN" ]] && [[ "$VHOST_DOMAIN" == http* ]]; then
        VHOST_DOMAIN=$(getPureDomain)
    fi
}

function getPureDomain()
{
    echo "$VHOST_DOMAIN" | awk -F'[:\\/]' '{print $4}'
}

function checkCmdDependencies()
{
    local _dependencies=(
      nginx
      wget
      cat
      basename
      mkdir
      cp
      mv
      rm
      chown
      chmod
      date
      find
      awk
    )

    for cmd in "${_dependencies[@]}"
    do
        hash "${cmd}" &>/dev/null || _die "'${cmd}' command not found."
    done;
}

function createDefaultVhost()
{
    #@todo implementation
    _die "Vhost for default application not supported yet. Please specify correct --app=... parameter."
}

function createMagento2Vhost()
{
    _arrow "Vhost creation for Nginx started..."

    _arrow "Changing current working directory to ${VHOST_ROOT_DIR}..."
    cd "$VHOST_ROOT_DIR" || _die "Couldn't change current working directory to : ${VHOST_ROOT_DIR}."
    _success "Done"

    _arrow "Verifying the current directory is Magento2..."
    verifyCurrentDirIsMage2Root
    _success "Done"

    _arrow "Creating Nginx Vhost File..."
    prepareVhostFilePaths
    prepareM2VhostContent
    createVhostSymlinks
    _success "Done"

    # @todo change-ownership

    _arrow "Creating an entry to /etc/hosts file..."
    createEtcHostEntry
    _success "Done"

    _arrow "Reloading the Nginx configuration..."
    reloadNginx
    _success "Done"
}

function verifyCurrentDirIsMage2Root()
{
    if [[ ! -f './bin/magento' ]] || [[ ! -f './app/etc/di.xml' ]]; then
        _die "Current directory is not Magento2 root. Please specify correct --root-dir=... parameter if you are running command from different directory."
    fi
}

function prepareVhostFilePaths()
{
    NGINX_SITES_ENABLED_FILE="${NGINX_SITES_ENABLED_DIR}/${VHOST_DOMAIN}.conf"
    NGINX_SITES_AVAILABLE_FILE="${NGINX_SITES_AVAILABLE_DIR}/${VHOST_DOMAIN}.conf"
}

function prepareM2VhostContent()
{
    local _mage2NginxFile=
    if [[ -f "${VHOST_ROOT_DIR}/nginx.conf" ]]; then
        _mage2NginxFile="${VHOST_ROOT_DIR}/nginx.conf"
    else
        _mage2NginxFile="${VHOST_ROOT_DIR}/nginx.conf.sample"
    fi

    # @todo move it to template based
    # @todo add option for https

    echo "#Magento Vars
#set \$MAGE_ROOT ${VHOST_ROOT_DIR};
#set \$MAGE_MODE default; # or production or developer

# Example configuration:
#upstream fastcgi_backend {
#    # use tcp connection
#    server  127.0.0.1:9000;
#    # or socket
#    server   unix:/var/run/php5-fpm.sock;
#}
server {
    listen 80;
    server_name $VHOST_DOMAIN;
    set \$MAGE_ROOT ${VHOST_ROOT_DIR};
    set \$MAGE_MODE developer;
    include ${_mage2NginxFile};
}
" > "$NGINX_SITES_AVAILABLE_FILE" || _die "Couldn't write to file: ${NGINX_SITES_AVAILABLE_FILE}"

    _arrow "${NGINX_SITES_AVAILABLE_FILE} file has been created."
}

function createVhostSymlinks()
{
    ln -s "$NGINX_SITES_AVAILABLE_FILE" "$NGINX_SITES_ENABLED_FILE" || _die "Couldn't create symlink to file: ${NGINX_SITES_AVAILABLE_FILE}"
}

function createEtcHostEntry()
{
    local _etcHostLine="127.0.0.1  ${VHOST_DOMAIN}"
    if grep -Eq "127.0.0.1[[:space:]]+${VHOST_DOMAIN}" /etc/hosts; then
        _warning "Entry ${_etcHostLine} already exists in host file"
    else
        echo "127.0.0.1  ${VHOST_DOMAIN}" >> /etc/hosts || _die "Unable to write host to /etc/hosts"
    fi
}

function reloadNginx()
{
    local _nginxTest=$(nginx -t)
    if [[ $? -eq 0 ]]; then
        nginx -s reload || _die "Nginx couldn't be reloaded."
    else
        echo "$_nginxTest"
    fi
}

function printSuccessMessage()
{
    _success "Virtual host for Nginx has been successfully created!"

    echo "################################################################"
    echo ""
    echo " >> Domain               : ${VHOST_DOMAIN}"
    echo " >> Application          : ${APP_TYPE}"
    echo " >> Document Root        : ${VHOST_ROOT_DIR}"
    echo " >> Nginx Config File    : ${NGINX_SITES_ENABLED_FILE}"
    echo ""
    echo "################################################################"

    _printPoweredBy

}

################################################################################
# Main
################################################################################
export LC_CTYPE=C
export LANG=C

DEBUG=0
_debug set -x
VERSION="0.1.0"

function main()
{
    _checkRootUser

    checkCmdDependencies

    [[ $# -lt 1 ]] && _printUsage

    initDefaultArgs

    processArgs "$@"

    # @todo wordpress | magento | default
    if [[ "$APP_TYPE" = 'magento2' ]]; then
        createMagento2Vhost
    else
        createDefaultVhost
    fi

    printSuccessMessage

    exit 0
}

main "$@"

_debug set +x