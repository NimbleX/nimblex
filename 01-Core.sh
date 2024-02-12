#!/bin/bash
#bash +x
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`${ARCH} # NimbleX Package name

if [[ -f .ftp-credentials ]]; then
  . .ftp-credentials
  slacksrc="ftp://${USERNAME}:${PASSWORD}@${HOSTNAME}/Bogdan/packages/slackware${ARCH}/slackware${ARCH}"
else
  slacksrc="ftp://slackware.telecoms.bg/slackware/slackware${ARCH}-current/slackware${ARCH}"
fi

blacklist_a="kernel-[ghm]*,mkinitrd*,elvis*,floppy*,mtx*,tcsh*,ed*,sharutils*,loadlin*,devs*,sysvinit-*,eudev-*,grub-*,dbus-*" # For now we exclude grub untill we decide to just clean it.
blacklist_ap="ghostscript*,hplip*,mariadb-*,vim*,linuxdoc*,man*,zsh*,groff*,gutenprint*,a2ps*,texinfo*,ksh93*,jed*,enscript*,cupsddk*,joe*,ispell*,jove*,pm-utils-*,qpdf-*"
whitelist_l="libseccomp-*,ncurses*,libgphoto2*,parted*,taglib*,apr*,fuse*,libusb-*,zlib*,lzo*,libmad*,libtermcap*,libcap*,gdbm*,popt*,libao*,libid3tag*,mm*,libmowgli*,libmcs*,libaio*,alsa*,libnl*,libpcap*,libzip*,ConsoleKit2-*,libunistring-*,elfutils-*,xxHash-*,lz4-*,lmdb-*,libuv-*"
whitelist_l=$whitelist_l",gmp*,libidn-*,libidn2-*,glib*,aalib*,libcaca*,gd*,audiofile*,dbus*,esound*,libieee1284*,libogg*,libtheora*,libvorbis*,libcddb*,libsamplerate*,libraw1394*,v4l-utils*,liboil*,mpfr*,wavpack*,libcdio*,expat*,urwid*,neon*,pcre*,libmpc*,libsndfile*,libnotify*,fftw*,libarchive*,libksba*,pygobject*,libmcrypt*,libssh-*,libatasmart-*,libffi-*,pycurl-*,libproxy-*,icu4c-*,libtasn1-*,libevent-*,jemalloc-*,libimobiledevice-*,libusbmuxd-*,usbmuxd-*,keyutils-*,libxml2-*,orc-*,svgalib-*,a52dec-*,polkit-*,libnih-*,libplist-*,gc-*,pulseaudio-*,alsa-plugins-*,sbc-*,json-c-*,libasyncns-*,libsigc++-*,speexdsp-*,libssh2-*,mozilla-nss-*,libvpx-*,js185-*,ffmpeg-*,lame-*,libbluray-*,SDL2*,libyaml-*,pyparsing-*,python-six-*,opus*,libopusenc-*,speex-*,jansson-*,brotli-*,readline-*,newt-*,libpcap-*,libedit-*,python-Jinja2-*,zstd-*,argon2-*,libptytty-*"

whitelist_n="libtirpc-*,libndp-*,nghttp2-*,nmap*,links*,bind*,curl*,tcpdump*,openssh*,dhcpcd-*,dhcp-*,libgcrypt*,ppp*,bluez*,wget*,iproute2*,wpa_supplicant*,iptables*,iptraf*,openvpn-*,libmnl-*,openssl*,rsync*,gpgme*,dnsmasq*,wireless_tools*,ipw*,vsftpd*,net-tools*,stunnel*,pth*,obex*,openobex*,rp-pppoe*,tcp_wrappers*,netpipes*,iputils*,libgpg*,telnet*,nc-*,ethtool*,rdist*,mtr*,tftp-hpa*,netkit-ftp*,whois*,zd1211*,bridge-utils*,portmap*,network-scripts*,inetd*,popa3d*,bsd-finger*,traceroute*,iw*,crda*,pssh*,biff+comsat*,icmpinfo*,rfkill*,idnkit*,libassuan*,ipset-*,ebtables-*,npth-*"
whitelist_n=$whitelist_n",httpd*,gnutls*,sendmail*,cyrus-sasl*,openldap-client*,nfs-utils*,procmail*,netwatch*,vlan*,netkit-routed*,netwrite*,gnupg-*,iftop-,mobile-broadband-provider-info-*,ca-certificates-*,libksba-*,gnupg2-*,nettle-*,p11-kit-*,NetworkManager-*,ModemManager-*,libmbim-*,libqmi-*,mobile-broadband-provider-info-*,ntp-*,libnetfilter_queue-*,libnfnetlink-*,wireguard-tools-*"

extra="chillispot,scanssh,nrg2iso,mdf2iso"
extra_lib=""

mkdir -p $NP $NP-work $NP-removed

downloadpkg() {
cd $SD/$NP-work
wget -N "$slacksrc"/a/*.tgz				# gzip, tar, xz, pkgtools 1.2MB
wget -N -R "$blacklist_a" "$slacksrc"/a/*.txz			# 23.9	MB
wget -N -R "$blacklist_ap" "$slacksrc"/ap/*.t[g-x]z		# 7	MB
wget -N -A "$whitelist_l" "$slacksrc"/l/*.txz			# 7.6	MB
wget -N -A "$whitelist_n" "$slacksrc"/n/*.txz			# 17.2	MB

echo Use the script that downloads slacky packages by name because this is a bit to much to maintain

#wget -N $slacksrc/d/python2-2.*.txz		# 12732K
wget -N $slacksrc/d/perl-5.*.txz		# 15532K - should be 5.3M after cleanup
wget -N $slacksrc/d/libtool-2.*.txz		# 420K
wget -N $slacksrc/d/python-setuptools-*.txz	# 676K
if [[ $ARCH = "" ]]; then
 wget -N http://packages.nimblex.net/nimblex/sshfs-fuse-2.3-i486-1.tgz		# 55K
 wget -N http://packages.nimblex.net/nimblex/systemd-221-i686-1.txz		# 5.1M
 wget -N http://packages.nimblex.net/nimblex/grub2-2.00-slim-i486-1.txz		# 1.1M
 wget -N http://packages.nimblex.net/nimblex/atop-1.26-i486-1.tgz		# 113K
 wget -N http://packages.nimblex.net/nimblex/ncdu-1.8-i486-1.tgz		# 28K
 wget -N http://packages.nimblex.net/nimblex/radvd-1.9.1-i486-1.tgz		# 71K
 wget -N http://packages.nimblex.net/nimblex/tdb-1.0.6-i486-1.tgz		# 50K
 wget -N http://packages.nimblex.net/nimblex/csync-0.49.9-i486-1.txz		# 88K
 wget -N http://packages.nimblex.net/nimblex/perl-Authen-SASL-2.16-i486-1.txz	# 46K
 wget -N http://packages.nimblex.net/nimblex/perl-IO-Socket-SSL-1.76-i486-1ponce.txz #52K
 wget -N http://packages.nimblex.net/nimblex/perl-Net-SMTP-SSL-1.01-i486-1ponce.txz #5K
 wget -N https://software.jaos.org/slackpacks/slackware-15.0/slapt-get/slapt-get-0.11.8-x86_64-1.txz
 wget -N http://packages.nimblex.net/nimblex/urlgrabber-3.10-i686-1.txz		# 84K
 wget -N http://packages.nimblex.net/nimblex/snappy-1.1.2-i686-1.txz		# 49K
 wget -N http://packages.nimblex.net/nimblex/confuse-2.7-i686-1.txz		# 51K
 wget -N http://packages.nimblex.net/nimblex/yajl-2.1.0-i686-1.txz		# 41K
 wget -N http://packages.nimblex.net/nimblex/libev-4.11-i486-2.txz		# 134K
elif [[ $ARCH = "64" ]]; then
 wget -N http://packages.nimblex.net/nimblex/audit-3.0.9-x86_64-1.txz		# 629K
 wget -N http://packages.nimblex.net/nimblex/dbus-1.12.20-x86_64-2.txz		# 505K
 wget -N http://packages.nimblex.net/nimblex/systemd-253-x86_64-1.txz		# 6.9M
# wget -N http://packages.nimblex.net/nimblex/grub2-2.00-slim-x86_64-1.txz	# 1.1M
 wget -N http://packages.nimblex.net/nimblex/ncdu-1.15.1-x86_64-1.txz		# 42K
 wget -N http://packages.nimblex.net/nimblex/confuse-3.2-x86_64-1.txz		# 66K
 wget -N http://packages.nimblex.net/nimblex/perl-AnyEvent-7.17-x86_64-1.txz	# 384K
 wget -N http://packages.nimblex.net/nimblex/perl-JSON-XS-4.03-x86_64-1.txz	# 88K
 wget -N http://packages.nimblex.net/nimblex/perl-common-sense-3.75-x86_64-1.txz	# 16K
 wget -N http://packages.nimblex.net/nimblex/perl-Canary-Stability-2006-x86_64-1.txz	# 8K
 wget -N http://packages.nimblex.net/nimblex/perl-Types-Serialiser-1.01-x86_64-1.txz	# 16K
 wget -N https://software.jaos.org/slackpacks/slackware64-15.0/slapt-get/slapt-get-0.11.9-x86_64-1.txz
 wget -N http://packages.nimblex.net/nimblex/yajl-2.1.0-x86_64-1.txz		# 38K
 wget -N http://packages.nimblex.net/nimblex/libev-4.33-x86_64-1.txz		# 138K
# wget -N http://packages.nimblex.net/nimblex/iperf3-3.7-x86_64-1.txz		# 84K
# wget -N http://packages.nimblex.net/nimblex/xl2tpd-1.3.2-x86_64-1.txz		# 430K
# wget -N http://packages.nimblex.net/nimblex/strongswan-5.6.2-x86_64-1.txz	# 863K
# # The following are some basic music apps related libs
# wget -N http://packages.nimblex.net/nimblex/dssi-1.1.1-x86_64-1.txz		# 48K
# wget -N http://packages.nimblex.net/nimblex/libconfig-1.6-x86_64-1.txz	# 86K
# wget -N http://packages.nimblex.net/nimblex/liblo-0.28-x86_64-1.txz		# 69K
# wget -N http://packages.nimblex.net/nimblex/lv2-1.10.0-x86_64-1.txz		# 146K
# wget -N http://packages.nimblex.net/nimblex/slv2-0.6.6-x86_64-2.txz		# 56K
# wget -N http://packages.nimblex.net/nimblex/liblrdf-0.5.0-x86_64-1.txz	# 24K
# wget -N http://packages.nimblex.net/nimblex/serd-0.20.0-x86_64-1.txz		# 49K
# wget -N http://packages.nimblex.net/nimblex/sord-0.12.2-x86_64-1.txz		# 31K
# wget -N http://packages.nimblex.net/nimblex/sratom-0.4.6-x86_64-1.txz		# 16K
# wget -N http://packages.nimblex.net/nimblex/liblrdf-0.5.0-x86_64-1.txz	# 24K
# wget -N http://packages.nimblex.net/nimblex/lilv-0.20.0-x86_64-1.txz		# 59K
# wget -N http://packages.nimblex.net/nimblex/celt051-0.5.1.3-x86_64-2.txz	# 47K
# wget -N http://packages.nimblex.net/nimblex/TLP-master-x86_64-1.txz		# 60K
fi
}

instpkg() {
for pkg in $SD/$NP-work/* ; do
   installpkg --root $SD/$NP $pkg
done
}

clean-core() {
cd $SD/$NP
# Remove stuff we don't need
echo "Starting the core cleanup procedure ... ;)"

ln -s /mnt/live/bin/vi bin/vi

rm etc/rc.d/rc.pcmcia
rm etc/rc.d/rc.inetd
chmod +x etc/rc.d/rc.bluetooth
sed -i 's/darkstar/nimblex/g' etc/hosts
sed -i 's/#   ForwardAgent no/    ForwardAgent yes/' etc/ssh/ssh_config
sed -i 's/#   StrictHostKeyChecking ask/    StrictHostKeyChecking no/' etc/ssh/ssh_config

#sed -i 's/darkstar/nimblex/g' etc/rc.d/rc.M
#sed -i 's/LESS="-M"/LESS="-MR"/' etc/profile

# systemD related. Perhaps these would be better ran from tmpfiles.d/nimblex.conf
mv lib/systemd/systemd.new lib/systemd/systemd
ln -s /bin/systemctl bin/reboot
ln -s /bin/systemctl bin/halt
ln -s /bin/systemctl bin/poweroff
#ln -s /run/dbus/system_bus_socket var/run/dbus/
rm etc/mtab && ln -s /proc/self/mounts etc/mtab
sed -i '/lockdev 0775 root lock/'d usr/lib/tmpfiles.d/legacy.conf

# ln -s /usr/share/zoneinfo/GMT0 etc/localtime # This should be handled by tmpfiles.d/etc.conf

rm etc/slackware-version

rm boot/*

mkdir -p etc/smack/accesses.d
echo "nimblex" > etc/HOSTNAME
echo "NimbleX Linux." > etc/motd
echo "<html><body><h1>NimbleX is running your web server!</h1></body></html>" > var/www/htdocs/index.html
echo "WORKINGDIR=/var/slapt-get
EXCLUDE=^aaa_elflibs,^devs,^glibc-.*,^kernel-.*,^udev,.*-[0-9]+dl$
SOURCE=http://packages.nimblex.net/slackware${ARCH}/:OFFICIAL
" > etc/slapt-get/slapt-getrc

rm -r media/* mnt/*
rm -r usr/{doc,share/gtk-doc}
rm usr/info/*
rm -r usr/share/mc/{help,hints}  # ~300KB
rm -r usr/share/zenmap/pixmaps # 270KB
rm -r usr/share/svgalib-demos # 64KB 
rm -r var/www/htdocs/manual # 730KB
rm usr/share/sounds/alsa/* # 730KB
rm usr/bin/omshell	# 470KB
rm usr/sbin/dhcrelay	# 480KB

# Removing firmware for hardware which is not mainstream. Saves 10M
cd lib/firmware
rm -r ueagle-atm/ libertas/ phanfw.bin ti-connectivity/ bnx2/ bnx2x* vxge/ myri10ge_* slicoss/ ql2*_fw.bin qlogic/ cxgb* liquidio/ netronome/ mellanox/ qed/
cd ../..

# Clean sone small stuff
rm usr/share/applications/{cups.desktop,wpa_gui.desktop}

# Handle Man pages
mkdir -p ../$NP-removed/man_pages/usr/man/ && mv usr/man/* $_
mkdir -p ../$NP-removed/man_pages/usr/local/man/ && mv usr/local/man/* $_

# Handle locale
mkdir -p ../$NP-removed/locale/usr/share/locale/ && mv usr/share/locale/* $_
#mkdir -p ../$NP-removed/locale/usr/lib${ARCH}/locale/ && mv usr/lib${ARCH}/locale/* $_

# Handle .h & .a files
mkdir -p ../$NP-removed/devel/usr/include/ && mv usr/include/* $_
mkdir -p ../$NP-removed/devel/lib${ARCH}/ && mv lib${ARCH}/*.a $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/ && mv usr/lib${ARCH}/*.a $_

# Slim down Perl some more because it's a HUGE bitch
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/perl5/auto/Encode/ && mv usr/lib${ARCH}/perl5/auto/Encode/{JP,KR,CN,TW} $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/perl5/CORE/ && mv usr/lib${ARCH}/perl5/CORE/*.h $_
mkdir -p ../$NP-removed/devel/usr/share/perl5/ && mv usr/share/perl5/pod $_

# Edit usr/share/cups/data/testprint.ps ?
# Handle usr/share/kbd/(consolefonts)(keymaps) ? #750KB
# Handle usr/share/nmap/(nmap-mac-prefixes)(nmap-os-db) ? #260KB
# Handle usr/share/terminfo # 200KB
# Handle usr/share/zoneinfo $ 200KB
}

copy-static() {
#mkdir -p usr/lib/sysusers.d # remove this after systemd is upgraded
echo "Copying stuff from 06-NimbleX"
cp ../06-NimbleX/etc/issue* etc/
cp ../06-NimbleX/etc/dhcpd.conf etc/
cp ../06-NimbleX/etc/vsftpd.conf etc/
cp ../06-NimbleX/etc/bootchartd.conf etc/
cp ../06-NimbleX/etc/profile etc/
cp ../06-NimbleX/etc/locale.conf etc/
cp ../06-NimbleX/etc/vconsole.conf etc/
cp ../06-NimbleX/etc/rc.local etc/
cp ../06-NimbleX/etc/default/grub etc/default/
cp ../06-NimbleX/etc/sysctl.d/99-nimblex.conf etc/sysctl.d/
cp ../06-NimbleX/etc/skel/{\.bashrc,\.screenrc} etc/skel/
cp ../06-NimbleX/etc/skel/{\.bashrc,\.screenrc} root/
# cp ../06-NimbleX/etc/slapt-get/slapt-getrc etc/slapt-get/
# cp ../06-NimbleX/usr/share/wallpapers/nimblex-wallpaper.jpg usr/share/wallpapers/
cp ../06-NimbleX/var/spool/mail/root var/spool/mail/root

cp ../06-NimbleX/etc/os-release etc/
cp ../06-NimbleX/lib/udev/rules.d/*.rules lib/udev/rules.d/
cp ../06-NimbleX/etc/systemd/coredump.conf etc/systemd/
#cp ../06-NimbleX/etc/dbus-1/system.d/* etc/dbus-1/system.d/
cp -a ../06-NimbleX/lib/systemd/system/*.{service,socket} lib/systemd/system/
cp -a ../06-NimbleX/lib/systemd/system/*.target.wants lib/systemd/system/

cp ../06-NimbleX/usr/bin.noarch/* usr/bin/
if [[ $ARCH = "" ]]; then
cp ../06-NimbleX/sbin/* sbin/
cp ../06-NimbleX/usr/bin/* usr/bin/
cp ../06-NimbleX/usr/sbin/* usr/sbin/
elif [[ $ARCH = "64" ]]; then
cp ../06-NimbleX/usr/bin64/* usr/bin/
fi
}

run-ldconfig() {
echo "Running ldconfig and others chrooted"
chroot . ldconfig
chroot . /usr/sbin/update-ca-certificates
#chroot . /usr/sbin/groupadd -g215 vboxusers 2> /dev/null # We'll move this to sysusers.d
}

SQUASH_OPT="-comp xz -noappend -b 256K -Xbcj x86 -no-xattrs"

if [[ -z $1 ]]; then
	echo "Tell me what to do"
	echo "You options are: clean download install lzmfy world"
else
	case $1 in
	 "clean" )
	  echo "...CLEANING"
	  rm -r $NP && echo $NP deleted
	  rm -r $NP-work && echo $NP-work deleted
	  rm -r $NP-removed && echo $NP-removed deleted
	 ;;
	 "download" )
	  echo "...DOWNLOADING"
	  downloadpkg
	 ;;
	 "install" )
	  echo "...INSTALLING"
	  instpkg
	  clean-core
	  copy-static
	  run-ldconfig
	 ;;
	 "lzmfy" )
	  echo "...LZMFY"
	  mksquashfs $SD/$NP $SD/$NP.lzm $SQUASH_OPT
	 ;;
	 "world" )
	  echo "...DOWNLOADING"
	  downloadpkg
	  echo "...INSTALLING"
	  instpkg
	  clean-core
	  copy-static
	  run-ldconfig
	  echo "...LZMFY"
	  mksquashfs $SD/$NP $SD/$NP.lzm $SQUASH_OPT
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi

