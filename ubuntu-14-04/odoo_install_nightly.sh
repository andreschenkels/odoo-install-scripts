#!/bin/bash

#################################################################################
# Script for Installation: ODOO nightly builds on Ubuntu 14.04 LTS
# Author: (c) Martin Brehmer 2016
#--------------------------------------------------------------------------------
#
# This script will install ODOO from the package sources for the nightly builds
# on a clean Ubuntu 14.04 Server
#
#--------------------------------------------------------------------------------
#
# USAGE: (sudo) odoo_install_nightly.sh
#
# EXAMPLE: sudo ./odoo_install_nightly.sh
#
#################################################################################

# check for root-privileges
if [ $EUID -ne 0 ]; then
	echo "You need root privileges to do this!" >&2
	exit 1
fi

# Enter the Version you want to install. Possible values are 8.0 or 9.0
OE_VERSION="8.0"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
apt-get update && apt-get dist-upgrade -y

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL ----"
apt-get install postgresql -y

echo -e "\n---- Install and link wkhtml as needed for ODOO 8.0 ----"
wget http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb && \
dpkg -i wkhtmltox-0.12.1_linux-trusty-amd64.deb
if [ $? -eq 0 ]; then
	ln -s /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf
	ln -s /usr/local/bin/wkhtmltoimage /usr/bin/wkhtmltoimage
else
	echo "\nThe installation of wkhtml was not successful!" >&2
	exit 1
fi

#--------------------------------------------------
# Add the package source to the list
#--------------------------------------------------
echo -e "\n---- Add package source ----"
wget -O - https://nightly.odoo.com/odoo.key | apt-key add -
echo "deb http://nightly.odoo.com/$OE_VERSION/nightly/deb/ ./" >> /etc/apt/sources.list

#--------------------------------------------------
# Install the actual nightly build of ODOO
#--------------------------------------------------
apt-get update && apt-get install odoo -y

echo "\nDone! The ODOO server is installed and should already run."

exit 0
