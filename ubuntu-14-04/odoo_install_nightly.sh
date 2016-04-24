#!/bin/bash

#################################################################################
# Script for Installation: odoo nightly builds on Ubuntu 14.04 LTS
# Author: (c) 2016 Martin Brehmer
#--------------------------------------------------------------------------------
#
# This script will install ODOO from the package sources for the nightly builds
# on a clean Ubuntu 14.04 Server
#
#--------------------------------------------------------------------------------
#
# USAGE: (sudo) odoo_install_nightly.sh [8.0|9.0]
#
# EXAMPLE: sudo ./odoo_install_nightly.sh 8.0
#
#################################################################################

# check for root-privileges
if [[ $EUID -ne 0 ]]; then
	echo "You need root privileges to do this!" >&2
	exit 1
fi

# check for invalid or too many parameters
if ([[ $# -eq 1 ]] && [[ $1 != "8.0" ]] && [[ $1 != "9.0" ]]) || ([[ $# -gt 1 ]]); then
	echo "USAGE: $0 [8.0|9.0]"
	exit 1
fi

# The Version of odoo you want to install. Default: 8.0
if [[ $# -eq 1 ]]; then
	OE_VERSION="$1"
else
	OE_VERSION="8.0"
fi

# check for 64 Bit or 32 Bit OS
OS_MACHINE_TYPE=$(uname -m)

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

echo -e "\n---- Install and link wkhtml as needed for odoo 8.0 ----"
apt-get install fontconfig fontconfig-config fonts-dejavu-core libfontconfig1 libjpeg-turbo8 libxrender1 -y
if [[ $OS_MACHINE_TYPE == "x86_64" ]]; then
	wget http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb && \
	dpkg -i wkhtmltox-0.12.1_linux-trusty-amd64.deb
else
	wget http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-i386.deb && \
	dpkg -i wkhtmltox-0.12.1_linux-trusty-i386.deb
fi
if [[ $? -eq 0 ]]; then
	ln -s /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf
	ln -s /usr/local/bin/wkhtmltoimage /usr/bin/wkhtmltoimage
else
	echo -e "\nThe installation of wkhtml was not successful!" >&2
	exit 1
fi

#--------------------------------------------------
# Add the package source to the list or change it
#--------------------------------------------------
echo -e "\n---- Add package source ----"
if [[ $OE_VERSION == "8.0" ]]; then
	if [[ $(grep -c 'deb http://nightly.odoo.com/9.0/nightly/deb/ ./' /etc/apt/sources.list) -eq 1 ]]; then
		apt-get remove odoo -y
		sed -i 's!deb http://nightly.odoo.com/9.0/nightly/deb/ ./!deb http://nightly.odoo.com/8.0/nightly/deb/ ./!' /etc/apt/sources.list
	elif [[ $(grep -c 'deb http://nightly.odoo.com/8.0/nightly/deb/ ./' /etc/apt/sources.list) -eq 0 ]]; then
		wget -O - https://nightly.odoo.com/odoo.key | apt-key add -
		echo "deb http://nightly.odoo.com/8.0/nightly/deb/ ./" >> /etc/apt/sources.list
	fi
elif [[ $OE_VERSION == "9.0" ]]; then
	if [[ $(grep -c 'deb http://nightly.odoo.com/8.0/nightly/deb/ ./' /etc/apt/sources.list) -eq 1 ]]; then
		apt-get remove odoo -y
		sed -i 's!deb http://nightly.odoo.com/8.0/nightly/deb/ ./!deb http://nightly.odoo.com/9.0/nightly/deb/ ./!' /etc/apt/sources.list
	elif [[ $(grep -c 'deb http://nightly.odoo.com/9.0/nightly/deb/ ./' /etc/apt/sources.list) -eq 0 ]]; then
		wget -O - https://nightly.odoo.com/odoo.key | apt-key add -
		echo "deb http://nightly.odoo.com/9.0/nightly/deb/ ./" >> /etc/apt/sources.list
	fi
else
	echo -e "\n Unsopported version number for odoo" >&2
	echo "USAGE: $0 [8.0|9.0]"
	exit 1
fi

#--------------------------------------------------
# Install the actual nightly build of odoo
#--------------------------------------------------
echo -e "\n---- Install odoo ----"
apt-get update && apt-get install odoo -y

echo -e "\nDone! The odoo server is installed and should already run."

exit 0
