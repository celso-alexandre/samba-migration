#!/bin/bash

set -e

appStart () {
	/usr/bin/supervisord
}

appSetup () {

	# Set variables
	DOMAIN=${DOMAIN:-SAMDOM.LOCAL}

	LDOMAIN=${DOMAIN,,}
	UDOMAIN=${DOMAIN^^}
	URDOMAIN=${UDOMAIN%%.*}

	# Setup Kerberos
	echo "[libdefaults]" > /etc/krb5.conf
	echo "    dns_lookup_realm = false" >> /etc/krb5.conf
	echo "    dns_lookup_kdc = true" >> /etc/krb5.conf
	echo "    default_realm = ${UDOMAIN}" >> /etc/krb5.conf

	# Set up supervisor (samba unconfigured)
	# Set up supervisor (samba configured)
	echo "[supervisord]" > /etc/supervisor/conf.d/supervisord.conf
	echo "nodaemon=true" >> /etc/supervisor/conf.d/supervisord.conf
	echo "" >> /etc/supervisor/conf.d/supervisord.conf
	echo "[program:samba]" >> /etc/supervisor/conf.d/supervisord.conf
	echo "command=/usr/local/samba/sbin/samba -i" >> /etc/supervisor/conf.d/supervisord.conf
	echo "" >> /etc/supervisor/conf.d/supervisord.conf
	echo "[program:webmin]" >> /etc/supervisor/conf.d/supervisord.conf
	echo "command=/usr/bin/perl /usr/share/webmin/miniserv.pl /etc/webmin/miniserv.conf" >> /etc/supervisor/conf.d/supervisord.conf

	# Is it needed to compile samba?
	if [[ ! -f /usr/local/samba/etc/smb.conf ]]; then
		
		if [[ -f /usr/local/samba/samba_to_compile/.configure && ! -d /usr/local/samba/sbin ]]; then
			
			cd /usr/local/samba/samba_to_compile
			./configure
			make -j 6
			make install

		else if [[ ! -d /usr/local/samba/sbin && ! -f /usr/local/samba/samba_to_compile/.configure ]]; then

			echo "Samba seems not yet compiled, but the /usr/local/samba/samba_to_compile/.configure script could not be found too. Did you forgot, or maybe placed it elsewhere?"

		else if [[ -d /usr/local/samba/sbin ]]; then

			echo "Samba appears to be compiled, but the smb.conf file is not in place. You must restore your backup."
		
		fi

	else; then		
		
		appStart

	fi
}

if [[ ! -f /etc/supervisor/conf.d/supervisord.conf || ! -f /usr/local/samba/etc/smb.conf ]]; then
	appSetup
else
	appStart
fi

exit 0