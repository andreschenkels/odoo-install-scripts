#!/bin/bash
################################################################################
# Script for Installation: ODOO 9.0 Community server on Ubuntu 15.04
# Author: André Schenkels, ICTSTUDIO 2015
#-------------------------------------------------------------------------------
#  
# This script will install ODOO Community Server on
# clean Ubuntu 15.04 Server
#-------------------------------------------------------------------------------
# USAGE:
#
# odoo-install
#
# EXAMPLE:
# ./odoo-install 
#
################################################################################
 
##fixed parameters
#openerp
OE_USER="odoo"
OE_HOME="/opt/$OE_USER"
OE_HOME_EXT="/opt/$OE_USER/$OE_USER-server"

#Enter version for checkout "9.0" for version 9.0,"8.0" for version 8.0, "7.0 (version 7), "master" for trunk
OE_VERSION="9.0"

#set the superadmin password
OE_SUPERADMIN="superadminpassword"
OE_CONFIG="$OE_USER-server"
INIT_FILE=/lib/systemd/system/$OE_CONFIG.service

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y locales

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
sudo dpkg-reconfigure locales
sudo locale-gen C.UTF-8
sudo /usr/sbin/update-locale LANG=C.UTF-8

echo -e "\n---- Set locales ----"
echo 'LC_ALL=C.UTF-8' >> /etc/environment

echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql -y
	
echo -e "\n---- PostgreSQL $PG_VERSION Settings  ----"
sudo sed -i s/"#listen_addresses = 'localhost'"/"listen_addresses = '*'"/g /etc/postgresql/9.4/main/postgresql.conf

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

sudo systemctl restart postgresql.service
#--------------------------------------------------
# System Settings
#--------------------------------------------------

echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install Basic Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo apt-get install wget git python-pip python-imaging python-setuptools python-dev libxslt-dev libxml2-dev libldap2-dev libsasl2-dev node-less postgresql-server-dev-all -y

echo -e "\n---- Install wkhtml and place on correct place for ODOO 8 ----"
sudo wget http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo dpkg -i wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo apt-get install -f -y
sudo dpkg -i wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo cp /usr/local/bin/wkhtmltopdf /usr/bin
sudo cp /usr/local/bin/wkhtmltoimage /usr/bin

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------

echo -e "\n==== Download ODOO Server ===="
cd $OE_HOME
sudo su $OE_USER -c "git clone --depth 1 --single-branch --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/"
cd -

echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install tool packages ----"
sudo pip install -r $OE_HOME_EXT/requirements.txt
	
#echo -e "\n---- Install python packages ----"
sudo easy_install pyPdf vatnumber pydot psycogreen suds ofxparse
	

#--------------------------------------------------
# Configure ODOO
#--------------------------------------------------
echo -e "* Create server config file"
sudo cp $OE_HOME_EXT/debian/openerp-server.conf /etc/$OE_CONFIG.conf
sudo chown $OE_USER:$OE_USER /etc/$OE_CONFIG.conf
sudo chmod 640 /etc/$OE_CONFIG.conf

echo -e "* Change server config file"
echo -e "** Remove unwanted lines"
sudo sed -i "/db_user/d" /etc/$OE_CONFIG.conf
sudo sed -i "/admin_passwd/d" /etc/$OE_CONFIG.conf
sudo sed -i "/addons_path/d" /etc/$OE_CONFIG.conf

echo -e "** Add correct lines"
sudo su root -c "echo 'db_user = $OE_USER' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'admin_passwd = $OE_SUPERADMIN' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'logfile = /var/log/$OE_USER/$OE_CONFIG$1.log' >> /etc/$OE_CONFIG.conf"
sudo su root -c "echo 'addons_path=$OE_HOME_EXT/addons,$OE_HOME/custom/addons' >> /etc/$OE_CONFIG.conf"

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/openerp-server --config=/etc/$OE_CONFIG.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------
sudo touch $INIT_FILE
sudo chmod 0700 $INIT_FILE

echo -e "* Create systemd unit file"
echo '[Unit]' >> $INIT_FILE
echo 'Description=ODOO Application Server' >> $INIT_FILE
echo 'Requires=postgresql.service' >> $INIT_FILE
echo 'After=postgresql.service' >> $INIT_FILE
echo '[Install]' >> $INIT_FILE
echo "Alias=$OE_CONFIG.service" >> $INIT_FILE
echo '[Service]' >> $INIT_FILE
echo 'Type=simple' >> $INIT_FILE
echo 'PermissionsStartOnly=true' >> $INIT_FILE
echo "User=$OE_USER" >> $INIT_FILE
echo "Group=$OE_USER" >> $INIT_FILE
echo "SyslogIdentifier=$OE_CONFIG" >> $INIT_FILE
echo "PIDFile=/run/odoo/$OE_CONFIG.pid" >> $INIT_FILE
echo "ExecStartPre=/usr/bin/install -d -m755 -o $OE_USER -g $OE_USER /run/odoo" >> $INIT_FILE
echo "ExecStart=/opt/odoo/odoo-server/openerp-server -c /etc/$OE_CONFIG.conf --pid=/run/odoo/$OE_CONFIG.pid --syslog $OPENERP_ARGS" >> $INIT_FILE
echo 'ExecStop=/bin/kill $MAINPID' >> $INIT_FILE
echo '[Install]' >> $INIT_FILE
echo 'WantedBy=multi-user.target' >> $INIT_FILE

echo -e "* Enabling Systemd File"
sudo systemctl enable $INIT_FILE

echo -e "-- Starting ODOO Server --"
sudo systemctl start $OE_CONFIG.service

