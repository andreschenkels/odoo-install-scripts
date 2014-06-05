#!/bin/bash
################################################################################
# Script for Installation: ODOO Saas4/Trunk server on Ubuntu 14.04 LTS
# Author: André Schenkels, ICTSTUDIO 2014
#-------------------------------------------------------------------------------
#
# This script will install ODOO Server on
# clean Ubuntu 14.04 Server
#-------------------------------------------------------------------------------
# USAGE:
#
# odoo-install
#
# EXAMPLE:
# ./odoo-install
#
################################################################################
#
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script"; exit 1; }
#
##  Fixed parameters
#Enter version for checkout "7.0" for version 7.0, "saas-4" and "master" for trunk
OE_VERSION="saas-4"
# OE_VERSION="master"
#
OE_USER="odoo"
OE_HOME="/opt/${OE_USER}"
OE_HOME_EXT="/opt/${OE_USER}/${OE_VERSION}"

#set the superadmin password
OE_SUPERADMIN="superadminpassword"
OE_CONFIG="${OE_USER}-server"

# Create Start Up file
# .   .   .   .   .   .   .
function create_init_file()
{
  INIT_FILE=/etc/init.d/$OE_CONFIG
  #
  cat <<INITFILE > ${INIT_FILE}
#!/bin/sh
### BEGIN INIT INFO
# Provides: \$OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/bin:/sbin:/usr/bin
DAEMON=$OE_HOME_EXT/openerp-server
NAME=$OE_CONFIG
DESC=$OE_CONFIG

# Specify the user name (Default: odoo).
USER=$OE_USER

# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"

# pidfile
PIDFILE=/var/run/\${NAME}.pid

# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \${CONFIGFILE}"
[ -x \${DAEMON} ] || exit 0
[ -f \${CONFIGFILE} ] || exit 0

checkpid() {
  [ -f \${PIDFILE} ] || return 1
  pid=\$(cat \${PIDFILE})
  [ -d /proc/\${pid} ] && return 0
  return 1
}
#
case "\${1}" in
  start)
    echo -n "Starting \${DESC}: "
    start-stop-daemon --start --quiet --pidfile \${PIDFILE} \
    --chuid \${USER} --background --make-pidfile \
    --exec \${DAEMON} -- \${DAEMON_OPTS}
    echo "\${NAME}."
  ;;

  stop)
    echo -n "Stopping \${DESC}: "
    start-stop-daemon --stop --quiet --pidfile \${PIDFILE} \
    --oknodo
    echo "\${NAME}."
  ;;

  restart|force-reload)
    echo -n "Restarting \${DESC}: "
    start-stop-daemon --stop --quiet --pidfile \${PIDFILE} \
    --oknodo
    sleep 1
    start-stop-daemon --start --quiet --pidfile \${PIDFILE} \
    --chuid \${USER} --background --make-pidfile \
    --exec \${DAEMON} -- \${DAEMON_OPTS}
    echo "\${NAME}."
  ;;

  *)
    N=/etc/init.d/\${NAME}
    echo "Usage: \${NAME} {start|stop|restart|force-reload}" >&2
    exit 1
  ;;

esac
exit 0
INITFILE
#
echo "Commented out >>>"
: <<'COMMENTEDBLOCK_1'
COMMENTEDBLOCK_1
echo "End commented section. <<<"
  chmod 755 ${INIT_FILE}
  chown root: ${INIT_FILE}
  echo ""
  echo "Init file"
  echo "............"
  cat ${INIT_FILE}
  echo "............"
}
export -f create_init_file
#
#
# Create Server Config file
# .   .   .   .   .   .   .
function create_server_config_file()
{
  cat << CONFIGFILE > /etc/$OE_CONFIG.conf
[options]
; This is the password that allows database operations:
admin_passwd = ${OE_SUPERADMIN}
db_host = False
db_port = False
db_user = ${OE_USER}
db_password = False
logfile = /var/log/$OE_USER/$OE_CONFIG$1.log
addons_path = $OE_HOME_EXT/addons,$OE_HOME/custom/addons
CONFIGFILE
  chown $OE_USER:$OE_USER /etc/$OE_CONFIG.conf
  chmod 640 /etc/$OE_CONFIG.conf

  echo ""
  echo "Server Config file"
  echo "............"
  cat /etc/$OE_CONFIG.conf
  echo "............"
}
export -f create_server_config_file
#
#
# Create Start Up file
# .   .   .   .   .   .   .
function create_startup_file()
{
  cat << STARTUPFILE > $OE_HOME_EXT/start.sh
#!/bin/sh
sudo -u $OE_USER $OE_HOME_EXT/openerp-server --config=/etc/$OE_CONFIG.conf
STARTUPFILE
  chmod 755 $OE_HOME_EXT/start.sh
  echo ""
  echo "Startup file"
  echo "............"
  cat $OE_HOME_EXT/start.sh
  echo "............"
}
export -f create_startup_file
#
# Lazy call for apt updating
# .   .   .   .   .   .   .
function update_apt() {
  if [[ -f /tmp/lastApt ]]
  then
    if [[ $(find "/tmp/lastApt" -mmin +721) ]]
    then
      echo "Apt lists are stale."
    else
      echo "Apt lists recently refreshed."
      return
    fi
  else
    echo "Apt lists are stale."
  fi
  apt-get update
  apt-get upgrade -y
  apt-get dist-upgrade -y
  apt-get autoremove -y
  apt-get clean -y
  #
  touch /tmp/lastApt
}
export -f update_apt
#
# Idempotent call to GitHub
# .   .   .   .   .   .   .
function obtain_source()
{
pushd $OE_HOME_EXT
if [[ -f $OE_HOME_EXT/openerp-server ]]
then
  echo "Pulling . . . "
  git pull
else
  echo "Cloning . . . "
  git clone --branch $OE_VERSION https://www.github.com/odoo/odoo
fi
popd
}
#
export -f obtain_source
#
#
##################################################
##  Main Program
#
#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update apt repos ----"
update_apt

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
apt-get install postgresql -y

echo -e "\n---- PostgreSQL $PG_VERSION Settings  ----"
sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/9.3/main/postgresql.conf

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
apt-get install wget git python-pip -y

echo -e "\n---- Install python packages ----"
apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf -y

echo -e "\n---- Install python libraries ----"
pip install gdata

echo -e "\n---- Create ODOO system user ----"
adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER

echo -e "\n---- Create Log directory ----"
mkdir -p /var/log/$OE_USER
chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Getting ODOO Source ===="
mkdir -p $OE_HOME_EXT
obtain_source

echo -e "\n---- Setting permissions on home folder ----"
chown -R $OE_USER:$OE_USER $OE_HOME

echo -e "\n---- Create custom module directory ----"
su $OE_USER -c "mkdir -p $OE_HOME/custom"
su $OE_USER -c "mkdir -p $OE_HOME/custom/addons"
#
#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
create_init_file

echo -e "\n* Create server config file"
create_server_config_file

echo -e "\n* Create startup file"
create_startup_file

echo -e "* Start ODOO on Startup"
update-rc.d $OE_CONFIG defaults

echo "Done! The ODOO server can be started with /etc/init.d/$OE_CONFIG"
