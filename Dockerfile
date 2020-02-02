FROM ubuntu:latest
LABEL manteiner="celsoalexandre <celsoalexandre@NOSPAM.NO>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade -y

# Install all apps
# Install basic packages
RUN apt-get install -y nano

# The third line is for multi-site config (ping is for testing later)
RUN apt-get install -y pkg-config
RUN apt-get install -y attr acl ldap-utils winbind libnss-winbind libpam-winbind krb5-user krb5-kdc supervisor
RUN apt-get install -y openvpn inetutils-ping

# apt-show-versions bug fix: https://groups.google.com/forum/#!topic/beagleboard/jXb9KhoMOsk
RUN rm -f /etc/apt/apt.conf.d/docker-gzip-indexes
RUN apt-get purge -y apt-show-versions
RUN rm -f /var/lib/apt/lists/*lz4
RUN apt-get -o Acquire::GzipIndexes=false update
RUN apt-get install -y apt-show-versions

# Install webmin dependencies
RUN apt-get install -y unzip wget libnet-ssleay-perl libauthen-pam-perl libio-pty-perl
RUN wget -O webmin.deb https://prdownloads.sourceforge.net/webadmin/webmin_1.941_all.deb
RUN dpkg -i webmin.deb

# Install samba build dependencies
RUN apt-get install -y python3-dev python2.7-dev
ADD util/install_samba_dep.sh /util/install_samba_dep.sh
RUN chmod +x /util/install_samba_dep.sh
RUN /util/install_samba_dep.sh
RUN rm -rf /util

# Set up script and run
ENV PATH="/usr/local/samba/sbin:/usr/local/samba/bin:${PATH}"
ADD init.sh /init.sh
RUN chmod 755 /init.sh
CMD /init.sh setup