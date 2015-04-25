#!/bin/bash
#bash +x
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`${ARCH} # NimbleX Package name
slacksrc="ftp://ftp.rdsbv.ro/mirrors/slackware/slackware${ARCH}-current/slackware${ARCH}"
slacksrc="ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware${ARCH}-current/slackware${ARCH}"
slacksrc="ftp://admin:crdq2f6qwv@seif/Bogdan/packages/slackware${ARCH}/slackware${ARCH}"
extrasrc="http://repository.slacky.eu/slackware${ARCH}-14.0/"
extrasrc="http://packages.nimblex.net/slacky${ARCH}"

ToBeAdded=(ipcalc madwifi)


blacklist_a="kernel-[ghm]*,mkinitrd*,elvis*,floppy*,mtx*,tcsh*,ed*,sharutils*,loadlin*,devs*,apmd*,sysvinit-*,udev-*,grub-*" # For now we exclude grub untill we decide to just clean it.
blacklist_ap="ghostscript*,hplip*,mariadb-*,vim*,linuxdoc*,man*,zsh*,groff*,gutenprint*,a2ps*,texinfo*,ksh93*,jed*,enscript*,cupsddk*,joe*,ispell*,jove*,pm-utils-*"
whitelist_l="ncurses*,libgphoto2*,parted*,taglib*,apr*,fuse*,libusb*,zlib*,lzo*,libmad*,libtermcap*,libcap*,gdbm*,popt*,libao*,libid3tag*,mm*,libmowgli*,libmcs*,libaio*,alsa*,libnl*,libpcap*,libzip*,ConsoleKit-*"
whitelist_l=$whitelist_l",gmp*,libidn*,glib*,aalib*,libcaca*,gd*,audiofile*,dbus*,esound*,libieee1284*,libogg*,libtheora*,libvorbis*,libcddb*,libsamplerate*,libraw1394*,v4l-utils*,liboil*,mpfr*,wavpack*,libcdio*,expat*,urwid*,neon*,pcre*,libmpc*,libsndfile*,libnotify*,fftw*,libarchive*,libksba*,pygobject*,libmcrypt*,libssh-*,libatasmart-*,libffi-*,pycurl-*,libproxy-*,icu4c-*,libtasn1-*,libevent-*,keyutils-*,libxml2-*"

whitelist_n="nmap*,links*,bind*,curl*,tcpdump*,openssh*,dhcpcd-*,dhcp-*,libgcrypt*,ppp*,bluez*,wget*,iproute2*,wpa_supplicant*,iptables*,iptraf*,openvpn*,openssl*,rsync*,gpgme*,dnsmasq*,wireless-tools*,ipw*,vsftpd*,net-tools*,stunnel*,pth*,obex*,openobex*,rp-pppoe*,tcp_wrappers*,netpipes*,iputils*,libgpg*,telnet*,nc-*,ethtool*,rdist*,mtr*,tftp-hpa*,netkit-ftp*,whois*,zd1211*,bridge-utils*,portmap*,network-scripts*,inetd*,popa3d*,bsd-finger*,traceroute*,iw*,crda*,pssh*,biff+comsat*,icmpinfo*,rfkill*,idnkit*,libassuan*,ipset-*,ebtables-*"
whitelist_n=$whitelist_n",httpd*,gnutls*,sendmail*,cyrus-sasl*,openldap-client*,nfs-utils*,procmail*,netwatch*,vlan*,netkit-routed*,netwrite*,gnupg-*,iftop-,mobile-broadband-provider-info-*,ca-certificates-*,libksba-*,gnupg2-*,nettle-*,p11-kit-*"

slacky_get() {
if [[ -z $1 ]]; then
  if [[ ! -f PACKAGES.TXT ]]; then
    wget http://repository.slacky.eu/slackware-14.0/PACKAGES.TXT
  fi
  cat PACKAGES.TXT | grep -A 2 "PACKAGE NAME:" | grep $1 | grep "PACKAGE LOCATION:" | awk '{print $3}' | cut -b 3-
  wget -r -l 1 -np -nH -nd -A txz $extrasrc$SP
else
  echo "What Slacky package do you want to get?"
fi
}

extra="chillispot,scanssh,nrg2iso,mdf2iso"
extra_lib=""

mkdir -p $NP $NP-work $NP-removed

downloadpkg() {
cd $SD/$NP-work
wget -N "$slacksrc"/a/*.tgz				# gzip, tar, xz, pkgtools 1.2MB
wget -N -R "$blacklist_a" "$slacksrc"/a/*.txz			# 23.9	MB
wget -N -R "$blacklist_ap" "$slacksrc"/ap/*.t[g-x]z		# 7	MB
wget -N -A "$whitelist_l" -R "$blacklist_l" "$slacksrc"/l/*.txz	# 7.6	MB
wget -N -A "$whitelist_n" "$slacksrc"/n/*.txz			# 17.2	MB

echo Use the script that downloads slacky packages by name because this is a bit to much to maintain

wget -N $slacksrc/d/python-2.*.txz		# 11500K
wget -N $slacksrc/d/perl-5.*.txz		# 14500K - should be 5.3M after cleanup
wget -N $slacksrc/d/libtool-2.*.txz		# 365K
wget -N $slacksrc/tcl/tcl-8.*.txz		# 1655K
wget -N $slacksrc/../extra/wicd/wicd-1.*.txz	# 347K
wget -N http://packages.nimblex.net/nimblex/b43-firmware-5.100.138-fw-1.txz	# 145K
if [[ $ARCH = "" ]]; then
 wget -N http://packages.nimblex.net/nimblex/sshfs-fuse-2.3-i486-1.tgz		# 55K
 wget -N http://packages.nimblex.net/nimblex/systemd-200-i486-1.txz		# 4.2M
 wget -N http://packages.nimblex.net/nimblex/grub2-2.00-slim-i486-1.txz		# 1.1M
 wget -N http://packages.nimblex.net/nimblex/libnih-1.0.3.txz			# 336K
 wget -N http://packages.nimblex.net/nimblex/atop-1.26-i486-1.tgz		# 113K
 wget -N http://packages.nimblex.net/nimblex/ncdu-1.8-i486-1.tgz		# 28K
 wget -N http://packages.nimblex.net/nimblex/radvd-1.9.1-i486-1.tgz		# 71K
 wget -N http://packages.nimblex.net/nimblex/tdb-1.0.6-i486-1.tgz		# 50K
 wget -N http://packages.nimblex.net/nimblex/csync-0.49.9-i486-1.txz		# 88K
 wget -N http://packages.nimblex.net/nimblex/perl-Authen-SASL-2.16-i486-1.txz	# 46K
 wget -N http://packages.nimblex.net/nimblex/perl-IO-Socket-SSL-1.76-i486-1ponce.txz #52K
 wget -N http://packages.nimblex.net/nimblex/perl-Net-SMTP-SSL-1.01-i486-1ponce.txz #5K
 wget -N http://packages.nimblex.net/nimblex/slapt-get-0.10.2r-i386-1.tgz	# 277K
 wget -N http://packages.nimblex.net/nimblex/tmux-1.9a-x86_64-1.txz		# 216K
 wget -N http://packages.nimblex.net/nimblex/pyparsing-2.0.3-i686-1.txz		# 99K
 wget -N http://packages.nimblex.net/nimblex/urlgrabber-3.10-i686-1.txz		# 84K
 wget -N http://packages.nimblex.net/nimblex/snappy-1.1.2-i686-1.txz		# 49K
 wget -N http://packages.nimblex.net/nimblex/json-c-0.11-i686-1.txz		# 110K
 wget -N http://packages.nimblex.net/nimblex/pulseaudio-5.0-i686-1.txz		# 1.1M
 wget -N http://packages.nimblex.net/nimblex/confuse-2.7-i686-1.txz		# 51K
# wget -N $extrasrc/network/airpwn/1.4/airpwn-1.4-i486-4sl.txz			# 60K
# wget -N $extrasrc/utilities/bar/1.11.1/bar-1.11.1-i486-1sl.txz		# 37K
 wget -N $extrasrc/libraries/libdaemon/0.14/libdaemon-0.14-i486-4sl.txz		# 27K
 wget -N $extrasrc/libraries/libnet/1.1.6/libnet-1.1.6-i486-4sl.txz		# 150K
 wget -N $extrasrc/system/fuseiso/20070708/fuseiso-20070708-i486-8sl.txz	# 26K
 wget -N $extrasrc/network/nss-mdns/0.10/nss-mdns-0.10-i486-8sl.txz		# 25K
 wget -N $extrasrc/utilities/cabextract/1.4/cabextract-1.4-i486-3sl.txz		# 60K
 wget -N $extrasrc/development/lua/5.1.5/lua-5.1.5-i486-2sl.txz			# 196K
 wget -N $extrasrc/utilities/slackyd/1.0.20110809/slackyd-1.0.20110809-i486-4sl.txz # 47K
elif [[ $ARCH = "64" ]]; then
 wget -N $extrasrc/system/sshfs-fuse/2.5/sshfs-fuse-2.5-x86_64-1sl.txz		# 53K
 wget -N http://packages.nimblex.net/nimblex/systemd-218-x86_64-1.txz		# 3.1M
 wget -N http://packages.nimblex.net/nimblex/grub2-2.00-slim-x86_64-1.txz	# 1.1M
 wget -N http://packages.nimblex.net/nimblex/atop-2.1-x86_64-1.txz		# 111K
 wget -N http://packages.nimblex.net/nimblex/ncdu-1.10-x86_64-1.txz		# 36K
 wget -N http://packages.nimblex.net/nimblex/perl-Authen-SASL-2.16-x86_64-1.txz	# 46K
 wget -N http://packages.nimblex.net/nimblex/perl-IO-Socket-SSL-1.967-x86_64-1.txz #82K
 wget -N http://packages.nimblex.net/nimblex/perl-Net-SMTP-SSL-1.01-x86_64-1.txz  #6K
 wget -N http://packages.nimblex.net/nimblex/perl-TermReadKey-2.31-x86_64-0.txz	# 25K
 wget -N http://packages.nimblex.net/nimblex/pysetuptools-3.4.4-x86_64-1.txz	# 308K
 wget -N http://packages.nimblex.net/nimblex/slapt-get-0.10.2r-x86_64-1.tgz	# 281K
 wget -N http://packages.nimblex.net/nimblex/tmux-1.9a-x86_64-1.txz		# 216K
 wget -N http://packages.nimblex.net/nimblex/audit-2.3.6-x86_64-1.txz		# 449K
 wget -N http://packages.nimblex.net/nimblex/libseccomp-2.1.1-x86_64-1root.txz	# 55K
 wget -N http://packages.nimblex.net/nimblex/pyparsing-2.0.1-x86_64-1.txz	# 96K
 wget -N http://packages.nimblex.net/nimblex/urlgrabber-3.10-x86_64-1.txz	# 84K
 wget -N http://packages.nimblex.net/nimblex/snappy-1.1.2-x86_64-1.txz		# 49K
 wget -N http://packages.nimblex.net/nimblex/ipaddr-py-2.1.11-x86_64-1.txz	# 29K
 wget -N http://packages.nimblex.net/nimblex/pbr-0.8.0-x86_64-1.txz		# 63K
 wget -N http://packages.nimblex.net/nimblex/mod_wsgi-3.4-x86_64-1.txz		# 64K
 wget -N http://packages.nimblex.net/nimblex/json-c-0.11-x86_64-1.txz		# 109K
 wget -N http://packages.nimblex.net/nimblex/pulseaudio-5.0-x86_64-1.txz	# 1.2M
 wget -N $extrasrc/libraries/confuse/2.7/confuse-2.7-x86_64-3sl.txz		# 42K
 wget -N $extrasrc/utilities/bar/1.11.1/bar-1.11.1-x86_64-3sl.txz		# 41K
 wget -N $extrasrc/utilities/cabextract/1.4/cabextract-1.4-x86_64-2sl.txz	# 61K
 wget -N $extrasrc/development/lua/5.1.5/lua-5.1.5-x86_64-2sl.txz		# 203K
 wget -N $extrasrc/utilities/slackyd/1.0.20110808/slackyd-1.0.20110808-x86_64-2sl.txz # 51K
 # The following are some basic music apps related libs
 wget -N http://packages.nimblex.net/nimblex/dssi-1.1.1-x86_64-1.txz		# 48K
 wget -N http://packages.nimblex.net/nimblex/libconfig-1.4.9-x86_64-1.txz	# 93K
 wget -N http://packages.nimblex.net/nimblex/liblo-0.28-x86_64-1.txz		# 69K
 wget -N http://packages.nimblex.net/nimblex/lv2-1.10.0-x86_64-1.txz		# 146K
 wget -N http://packages.nimblex.net/nimblex/slv2-0.6.6-x86_64-2.txz		# 56K
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
echo "Starting the core cleanup procedure ... smen ;)"

ln -s /mnt/live/bin/vi bin/vi

chmod -x etc/rc.d/rc.pcmcia
chmod -x etc/rc.d/rc.inetd
chmod +x etc/rc.d/rc.bluetooth
sed -i 's/darkstar/nimblex/g' etc/hosts
sed -i 's/#   ForwardAgent no/    ForwardAgent yes/' etc/ssh/ssh_config
sed -i 's/#   StrictHostKeyChecking ask/    StrictHostKeyChecking no/' etc/ssh/ssh_config

#sed -i 's/darkstar/nimblex/g' etc/rc.d/rc.M
#sed -i 's/LESS="-M"/LESS="-MR"/' etc/profile

# systemD related. Perhaps these would be better ran from tmpfiles.d/nimblex.conf
ln -s /usr/lib/libffi.so.6.0.0 usr/lib/libffi.so.4
ln -s /bin/systemctl bin/reboot
ln -s /bin/systemctl bin/halt
ln -s /bin/systemctl bin/poweroff
rm etc/mtab && ln -s /proc/self/mounts etc/mtab
sed -i '/lockdev 0775 root lock/'d usr/lib/tmpfiles.d/legacy.conf
echo "PACKAGE NAME:     udev-219" > var/log/packages/udev-219-`uname -m`-1

rm -r etc/localtime
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
SOURCE=http://packages.nimblex.net/slacky${ARCH}/:OFFICIAL
" > etc/slapt-get/slapt-getrc
echo "cache = /var/slackyd
repository = http://packages.nimblex.net/slackware${ARCH}/
repository slacky${ARCH} = http://packages.nimblex.net/slacky${ARCH}/
blacklist ^udev-.* ^kernel-.*
" > etc/slackyd/slackyd.conf

rm -r media/* mnt/*
rm -r usr/{doc,share/gtk-doc}
rm usr/info/*
rm -r usr/share/mc/{help,hints}  # ~300KB
rm -r usr/share/zenmap/pixmaps # 270KB
rm -r var/www/htdocs/manual # 730KB
rm usr/share/sounds/alsa/* # 730KB
rm usr/bin/omshell	# 470KB
rm usr/sbin/dhcrelay	# 480KB
rm sbin/dhclient*	# 512KB

# Removing firmware for hardware which is not mainstream. Saves 10M
cd lib/firmware
rm -r ueagle-atm/ libertas/ phanfw.bin i6050-fw-usb-1.5.sbcf ti-connectivity/ bnx2/ i2400m-fw-usb-1.* bnx2x* vxge/ myri10ge_* slicoss/ ql2*_fw.bin qlogic/ cxgb*
cd ../..

# Clean sone small stuff
rm usr/share/applications/{cups.desktop,wpa_gui.desktop}

# Handle Man pages
mkdir -p ../$NP-removed/man_pages/usr/man/ && mv usr/man/* $_
mkdir -p ../$NP-removed/man_pages/usr/local/man/ && mv usr/local/man/* $_

# Handle locale
mkdir -p ../$NP-removed/locale/usr/share/locale/ && mv usr/share/locale/* $_
#mkdir -p ../$NP-removed/locale/usr/lib/locale/ && mv usr/lib/locale/* $_

# Handle .h & .a files
mkdir -p ../$NP-removed/devel/usr/include/ && mv usr/include/* $_
mv ../$NP-removed/devel/usr/include/python2.7 usr/include/	# Required at least by WICD

mkdir -p ../$NP-removed/devel/lib${ARCH}/ && mv lib${ARCH}/*.a $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/ && mv usr/lib${ARCH}/*.a $_

# Slim down Python some more because it's a HUGE bitch
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.7/ && mv usr/lib${ARCH}/python2.7/test $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.7/bsddb/ && mv usr/lib${ARCH}/python2.7/bsddb/test $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.7/ctypes/ && mv usr/lib${ARCH}/python2.7/ctypes/test $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.7/distutils/ && mv usr/lib${ARCH}/python2.7/distutils/tests $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.7/email/ && mv usr/lib${ARCH}/python2.7/email/test $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.7/json/ && mv usr/lib${ARCH}/python2.7/json/tests $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.7/lib2to3/ && mv usr/lib${ARCH}/python2.7/lib2to3/tests $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.7/sqlite3/ && mv usr/lib${ARCH}/python2.7/sqlite3/test $_
rm usr/lib${ARCH}/python2.7/distutils/command/wininst*

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
echo "Copying stuff from 06-NimbleX"
cp ../06-NimbleX/etc/issue* etc/
cp ../06-NimbleX/etc/dhcpd.conf etc/
cp ../06-NimbleX/etc/vsftpd.conf etc/
cp ../06-NimbleX/etc/bootchartd.conf etc/
cp ../06-NimbleX/etc/profile etc/
cp ../06-NimbleX/etc/default/grub etc/default/
cp ../06-NimbleX/etc/sysctl.conf etc/
cp ../06-NimbleX/etc/skel/{\.bashrc,\.screenrc} etc/skel/
cp ../06-NimbleX/etc/skel/{\.bashrc,\.screenrc} root/
# cp ../06-NimbleX/etc/slapt-get/slapt-getrc etc/slapt-get/
cp ../06-NimbleX/etc/rc.d/rc.* etc/rc.d/
# cp ../06-NimbleX/usr/share/wallpapers/nimblex-wallpaper.jpg usr/share/wallpapers/
cp ../06-NimbleX/var/spool/mail/root var/spool/mail/root

cp ../06-NimbleX/usr/lib/os-release usr/lib/ && ln -sf /usr/lib/os-release etc/
cp ../06-NimbleX/lib/udev/rules.d/*.rules lib/udev/rules.d/
cp -a ../06-NimbleX/lib/systemd/system/*.{service,socket} lib/systemd/system/
cp -a ../06-NimbleX/lib/systemd/system/*.target.wants lib/systemd/system/
cp ../06-NimbleX/usr/lib/sysusers.d/pulseaudio.conf usr/lib/sysusers.d/pulseaudio.conf


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
chroot . /usr/sbin/update-ca-certificates --fresh
#chroot . /usr/sbin/groupadd -g215 vboxusers 2> /dev/null # We'll move this to sysusers.d
chroot . /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas/
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

