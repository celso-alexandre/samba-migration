# This is a fork of the fmstrat repo at https://github.com/Fmstrat/samba-domain, but it comes with webmin pre-installed at the 10000 default port.
# This image serves the purpuse of migrating a compiled working Samba 4 dc and/or file server to a docker image.

## How to start

First, I strongly recommend you to install portainer to do everything in here easier through a web interface. Download portainer [here](https://www.portainer.io/).

Before the first run of this image, create a folder at the container path `/var/local/samba/samba_to_compile`, which means you must create a folder in your host machine (in our examples we use `/data/docker/containers/samba/data/samba_to_compile`) before creating this container, and after that, download the same version you wish to restore from your samba backup. For that, in your old samba server that you wish to replace, run `samba -V`, and then download at `https://download.samba.org/pub/samba/stable/samba-x.y.z.tar.gz`, replacing x.y.z with the correct version.
- Notice that it isn't recommended to directly upgrade your samba version at the same time you are restoring it to a different host (or container, in this case). Instead, the Samba team recommends to restore to the same version, test everything and then read the release notes of the above version, upgrade as recommended there, test everything again and repeat until you get to your desired version. For more information, [read here](https://wiki.samba.org/index.php/Upgrading_a_Samba_AD_DC) and principally these [Very important notes](https://wiki.samba.org/index.php/Using_the_samba_backup_script#Restore).

After you download this tar, untar it with `tar -zxf samba-x.y.z.tar.gz`, move the generated `samba-x.y.z` folder contents to the container path `/var/local/samba/samba_to_compile`, which is, in our examples the folder `/data/docker/containers/samba/data/samba_to_compile` in the host.

After that, you can run your container normally as described below and wait while the compilation finishes.

## Backup and restoring

After the compilation finishes, connect to your container with `docker container attach <containername>`, download your backup file(s) from somewhere and restore it.

For backup and restoring samba, I recommend reading the instructions find in the official Samba [Wiki](https://wiki.samba.org/index.php/Back_up_and_Restoring_a_Samba_AD_DC). Notice that there is a warning at the top of the page that warns you to see [this page](https://wiki.samba.org/index.php/Using_the_samba_backup_script) if your samba version is below 4.9.

## Environment variable for quick start
* `DOMAIN` defaults to `CORP.EXAMPLE.COM` and should be set to your domain

## Volumes for quick start
* `/etc/localtime:/etc/localtime:ro` - Sets the timezone to match the host
* `/data/docker/containers/samba/data/:/usr/local/samba` - Stores samba data, so you can put your downloaded samba version for compilation inside the `samba_to_compile` sub-folder before the first container run. And this way, it will be easier for you to centralize your backups.

## Downloading and building
```
mkdir -p /data/docker/builds
cd /data/docker/builds
git clone https://github.com/celso-alexandre/samba-migration.git
cd samba-migration
docker build -t samba-migration .
```

## Setting things up for the container
To set things up you will first want a new IP on your host machine so that ports don't conflict. A domain controller needs a lot of ports, and will likely conflict with things like dnsmasq. The below commands will do this, and set up some required folders.

```
ifconfig eno1:1 192.168.3.222 netmask 255.255.255.0 up
mkdir -p /data/docker/containers/samba/data
```

## Things to keep in mind
* In some cases on Windows clients, you would join with the domain of CORP, but when entering the computer domain you must enter CORP.EXAMPLE.COM. This seems to be the case when using most any samba based DC.
* Make sure your client's DNS is using the DC, or that your mail DNS is relaying for the domain
* Ensure client's are using corp.example.com as the search suffix

# Example with docker run

```
docker run -t -i \
	-e "DOMAIN=CORP.EXAMPLE.COM" \
	-p 192.168.3.222:53:53 \
	-p 192.168.3.222:53:53/udp \
	-p 192.168.3.222:88:88 \
	-p 192.168.3.222:88:88/udp \
	-p 192.168.3.222:135:135 \
	-p 192.168.3.222:137-138:137-138/udp \
	-p 192.168.3.222:139:139 \
	-p 192.168.3.222:389:389 \
	-p 192.168.3.222:389:389/udp \
	-p 192.168.3.222:445:445 \
	-p 192.168.3.222:464:464 \
	-p 192.168.3.222:464:464/udp \
	-p 192.168.3.222:636:636 \
	-p 192.168.3.222:1024-1044:1024-1044 \
	-p 192.168.3.222:3268-3269:3268-3269 \
  -p 192.168.3.222:10000:10000 \
	-v /etc/localtime:/etc/localtime:ro \
	-v /data/docker/containers/samba/data/:/usr/local/samba/ \	
	--dns-search corp.example.com \
	--dns 192.168.3.222 \
	--dns 192.168.3.1 \
	--add-host localdc.corp.example.com:192.168.3.222 \
	-h localdc \
	--name samba \
	--privileged \
	samba-migration
```

# Example with docker compose

Start a new domain, and forward non-resolvable queries to the main DNS server
* Local site is `192.168.3.0`
* Local DC (this one) hostname is `LOCALDC` using the host IP of `192.168.3.222`
* Local main DNS is running on `192.168.3.1`

```
version: '2'

networks:
  extnet:
    external: true

services:

# ----------- samba begin ----------- #

  samba:
    image: samba-migration
    container_name: samba
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /data/docker/containers/samba/data/:/usr/local/samba/      
    environment:
      - DOMAIN=CORP.EXAMPLE.COM
    networks:
      - extnet
    ports:
      - 192.168.3.222:53:53
      - 192.168.3.222:53:53/udp
      - 192.168.3.222:88:88
      - 192.168.3.222:88:88/udp
      - 192.168.3.222:135:135
      - 192.168.3.222:137-138:137-138/udp
      - 192.168.3.222:139:139
      - 192.168.3.222:389:389
      - 192.168.3.222:389:389/udp
      - 192.168.3.222:445:445
      - 192.168.3.222:464:464
      - 192.168.3.222:464:464/udp
      - 192.168.3.222:636:636
      - 192.168.3.222:1024-1044:1024-1044
      - 192.168.3.222:3268-3269:3268-3269
      - 192.168.3.222:10000:10000
    dns_search:
      - corp.example.com
    dns:
      - 192.168.3.222
      - 192.168.3.1
    extra_hosts:
      - localdc.corp.example.com:192.168.3.222
    hostname: localdc
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    privileged: true
    restart: always

# ----------- samba end ----------- #
```

## Webmin Integration
Webmin is installed on this forked docker image, so the port 10000 can be exposed for samba management
