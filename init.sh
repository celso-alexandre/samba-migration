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
	
	cd /usr/local/samba/samba_to_compile
	./configure
	make -j 6
	make install

	# Setup Kerberos
	echo "[libdefaults]" > /etc/krb5.conf
	echo "    dns_lookup_realm = false" >> /etc/krb5.conf
	echo "    dns_lookup_kdc = true" >> /etc/krb5.conf
	echo "    default_realm = ${UDOMAIN}" >> /etc/krb5.conf
        
	# Set up supervisor
	echo "[supervisord]" > /etc/supervisor/conf.d/supervisord.conf
	echo "nodaemon=true" >> /etc/supervisor/conf.d/supervisord.conf
	echo "" >> /etc/supervisor/conf.d/supervisord.conf
	echo "#[program:samba]" >> /etc/supervisor/conf.d/supervisord.conf
	echo "#command=/usr/local/samba/sbin/samba -i" >> /etc/supervisor/conf.d/supervisord.conf
	echo "" >> /etc/supervisor/conf.d/supervisord.conf
	echo "[program:webmin]" >> /etc/supervisor/conf.d/supervisord.conf
	echo "command=/usr/bin/perl /usr/share/webmin/miniserv.pl /etc/webmin/miniserv.conf" >> /etc/supervisor/conf.d/supervisord.conf
	
	appStart
}

if [[ -f /etc/supervisor/conf.d/supervisord.conf ]]; then
	appStart
else
	appSetup
fi

exit 0