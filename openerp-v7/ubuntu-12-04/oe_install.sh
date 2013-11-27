#!/bin/bash
################################################################################
# Script for Installation: OpenERP 7.0 server on Ubuntu 12.04 LTS
# Author: André Schenkels, ICTSTUDIO 2013
#-------------------------------------------------------------------------------
#  
# This script will install OpenERP Server with PostgreSQL server 9.2 on
# clean Ubuntu 12.04 Server
#-------------------------------------------------------------------------------
# USAGE:
#
# oe-install
#
# EXAMPLE:
# oe-install 
#
################################################################################
 
##fixed parameters
#openerp
OE_USER="openerp"
OE_HOME="/opt/openerp"

#set the revisions you want to use
OE_WEB_REV="3941"
OE_SERVER_REV="5004"
OE_ADDONS_REV="9154"

#set the superadmin password
OE_SUPERADMIN="superadminpassword"
OE_CONFIG="openerp-server"

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server 9.2  ----"
sudo wget -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
sudo su root -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main' >> /etc/apt/sources.list.d/pgdg.list"
sudo su root -c "echo 'Package: *' >> /etc/apt/preferences.d/pgdg.pref"
sudo su root -c "echo 'Pin: release o=apt.postgresql.org' >> /etc/apt/preferences.d/pgdg.pref"
sudo su root -c "echo 'Pin-Priority: 500' >> /etc/apt/preferences.d/pgdg.pref"
yes | sudo apt-get update
yes | sudo apt-get install pgdg-keyring
yes | sudo apt-get install postgresql-9.2

echo -e "\n---- Creating the OpenERP PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

echo -e "\n---- PostgreSQL Settings  ----"
sudo sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/9.2/main/postgresql.conf

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
yes | sudo apt-get install wget subversion bzr bzrtools python-pip
	
echo -e "\n---- Install python packages ----"
yes | sudo apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab \
python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2
	
echo -e "\n---- Install python libraries ----"
sudo pip install gdata
	
echo -e "\n---- Create OpenERP system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'OpenERP' --group $OE_USER

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install OpenERP
#--------------------------------------------------
echo -e "\n==== Installing OpenERP Server ===="

echo -e "\n---- Getting latest version from bazaar or specific revision ----"
sudo su $OE_USER -c "bzr branch lp:openobject-server/7.0 $OE_HOME/server -r $OE_SERVER_REV"
sudo su $OE_USER -c "bzr branch lp:openobject-addons/7.0 $OE_HOME/addons -r $OE_ADDONS_REV"
sudo su $OE_USER -c "bzr branch lp:openerp-web/7.0 $OE_HOME/web -r $OE_WEB_REV"

echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"
sudo cp $OE_HOME/server/install/openerp-server.conf /etc/$OE_CONFIG.conf
sudo chown $OE_USER:$OE_USER /etc/$OE_CONFIG.conf
sudo chmod 640 /etc/$OE_CONFIG.conf

echo -e "* Change server config file"
sudo sed -i s/"db_user = .*"/"db_user = $OE_USER"/g /etc/$OE_CONFIG.conf
sudo sed -i s/"; admin_passwd.*"/"admin_passwd = $OE_SUPERADMIN"/g /etc/$OE_CONFIG.conf
sudo su root -c "echo 'logfile = /var/log/$OE_USER/$OE_CONFIG$1.log' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'addons_path=$OE_HOME/addons,$OE_HOME/web/addons,$OE_HOME/custom/addons' >> /etc/$OE_CONFIG.conf"

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME/server/openerp-server --config=/etc/$OE_CONFIG.conf' >> $OE_HOME/start.sh"
sudo chmod 755 $OE_HOME/start.sh

#--------------------------------------------------
# Adding OpenERP as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
echo '#!/bin/sh' >> ~/$OE_CONFIG
echo '### BEGIN INIT INFO' >> ~/$OE_CONFIG
echo '# Provides: $OE_CONFIG' >> ~/$OE_CONFIG
echo '# Required-Start: @@@remote_fs @@@syslog' >> ~/$OE_CONFIG
echo '# Required-Stop: @@@remote_fs @@@syslog' >> ~/$OE_CONFIG
echo '# Should-Start: @@@network' >> ~/$OE_CONFIG
echo '# Should-Stop: @@@network' >> ~/$OE_CONFIG
echo '# Default-Start: 2 3 4 5' >> ~/$OE_CONFIG
echo '# Default-Stop: 0 1 6' >> ~/$OE_CONFIG
echo '# Short-Description: Enterprise Resource Management software' >> ~/$OE_CONFIG
echo '# Description: Open ERP is a complete ERP and CRM software.' >> ~/$OE_CONFIG
echo '### END INIT INFO' >> ~/$OE_CONFIG
echo 'PATH=/bin:/sbin:/usr/bin' >> ~/$OE_CONFIG
echo 'DAEMON=$OE_HOME/server/openerp-server' >> ~/$OE_CONFIG
echo 'NAME=$OE_CONFIG' >> ~/$OE_CONFIG
echo 'DESC=$OE_CONFIG' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Specify the user name (Default: openerp).' >> ~/$OE_CONFIG
echo 'USER=$OE_USER' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Specify an alternate config file (Default: /etc/openerp-server.conf).' >> ~/$OE_CONFIG
echo 'CONFIGFILE="/etc/@@@OE_CONFIG"' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# pidfile' >> ~/$OE_CONFIG
echo 'PIDFILE=/var/run/@@@NAME.pid' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo '# Additional options that are passed to the Daemon.' >> ~/$OE_CONFIG
echo 'DAEMON_OPTS="-c @@@CONFIGFILE"' >> ~/$OE_CONFIG
echo '[ -x @@@DAEMON ] || exit 0' >> ~/$OE_CONFIG
echo '[ -f @@@CONFIGFILE ] || exit 0' >> ~/$OE_CONFIG
echo 'checkpid() {' >> ~/$OE_CONFIG
echo '[ -f @@@PIDFILE ] || return 1' >> ~/$OE_CONFIG
echo 'pid=`cat @@@PIDFILE`' >> ~/$OE_CONFIG
echo '[ -d /proc/@@@pid ] && return 0' >> ~/$OE_CONFIG
echo 'return 1' >> ~/$OE_CONFIG
echo '}' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'case "@@@{1}" in' >> ~/$OE_CONFIG
echo 'start)' >> ~/$OE_CONFIG
echo 'echo -n "Starting @@@{DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile @@@{PIDFILE} \' >> ~/$OE_CONFIG
echo '--chuid @@@{USER} --background --make-pidfile \' >> ~/$OE_CONFIG
echo '--exec @@@{DAEMON} -- @@@{DAEMON_OPTS}' >> ~/$OE_CONFIG
echo 'echo "@@@{NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo 'stop)' >> ~/$OE_CONFIG
echo 'echo -n "Stopping @@@{DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile @@@{PIDFILE} \' >> ~/$OE_CONFIG
echo '--oknodo' >> ~/$OE_CONFIG
echo 'echo "@@@{NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'restart|force-reload)' >> ~/$OE_CONFIG
echo 'echo -n "Restarting @@@{DESC}: "' >> ~/$OE_CONFIG
echo 'start-stop-daemon --stop --quiet --pidfile @@@{PIDFILE} \' >> ~/$OE_CONFIG
echo '--oknodo' >> ~/$OE_CONFIG
echo 'sleep 1' >> ~/$OE_CONFIG
echo 'start-stop-daemon --start --quiet --pidfile @@@{PIDFILE} \' >> ~/$OE_CONFIG
echo '--chuid @@@{USER} --background --make-pidfile \' >> ~/$OE_CONFIG
echo '--exec @@@{DAEMON} -- @@@{DAEMON_OPTS}' >> ~/$OE_CONFIG
echo 'echo "@@@{NAME}."' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '*)' >> ~/$OE_CONFIG
echo 'N=/etc/init.d/@@@{NAME}' >> ~/$OE_CONFIG
echo 'echo "Usage: @@@{NAME} {start|stop|restart|force-reload}" >&2' >> ~/$OE_CONFIG
echo 'exit 1' >> ~/$OE_CONFIG
echo ';;' >> ~/$OE_CONFIG
echo '' >> ~/$OE_CONFIG
echo 'esac' >> ~/$OE_CONFIG
echo 'exit 0' >> ~/$OE_CONFIG

echo -e "* Replace @@@ with dollar sign"
sed -i s/"@@@"/"\$"/g ~/$OE_CONFIG

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Start OpenERP on Startup"
sudo update-rc.d $OE_CONFIG defaults
 
echo "Done!"

