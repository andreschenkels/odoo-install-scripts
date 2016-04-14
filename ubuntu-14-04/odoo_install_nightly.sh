#!/bin/bash

#################################################################################
# Script for Installation: ODOO nightly builds on Ubuntu 14.04 LST
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
# EXAMPLE sudo ./odoo_install_nightly.sh
#
#################################################################################

# check for root-privileges
if [[ $EUID -ne 0 ]]; then
	>&2 echo "You need root privileges to do this!"
	exit 1
fi

# Enter the Version you want to install. Possible values: 7.0, 8.0, 9.0
OE_VERSION="8.0"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
apt-get update && apt-get dist-upgrade -y
