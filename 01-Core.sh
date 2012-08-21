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
extrasrc="http://repository.slacky.eu/slackware${ARCH}-13.37/"
extrasrc="http://packages.nimblex.net/slacky${ARCH}"

ToBeAdded=(ipcalc madwifi)


blacklist_a="kernel-[ghm]*,mkinitrd*,elvis*,floppy*,mtx*,tcsh*,ed*,sharutils*,loadlin*,devs*,apmd*"
blacklist_ap="ghostscript*,hplip*,mysql*,vim*,linuxdoc*,man*,zsh*,groff*,gutenprint*,a2ps*,texinfo*,ksh93*,jed*,enscript*,cupsddk*,joe*,ispell*,jove*"
whitelist_ap="mc*,flac*,rpm*,cdrtools*,screen*,sox*,sqlite*,nano*,xfsdump*,ntfsprogs*,lsof*,diffutils*,sysstat*,gphoto2*,vorbis-tools*,dc3dd*,lm_sensors*,sudo*,dvd+rw-tools*,cdparanoia*,bc*,ash*,normalize*,madplay*,aumix*,slackpkg*,dmidecode*,seejpeg*,bpe*,pm-utils*,most*,at*,dmapi*,lsscsi*,vbetool*,rzip*,diffstat*,libx86*,radeontool*"
whitelist_l="ncurses*,libgphoto2*,parted*,taglib*,apr*,fuse*,libusb*,zlib*,lzo*,libmad*,libtermcap*,libcap*,gdbm*,popt*,libao*,libid3tag*,mm*,libmowgli*,libmcs*,libaio*,alsa*,libnl*,libpcap*,libzip*,ConsoleKit-*"
whitelist_l=$whitelist_l",gmp*,libidn*,glib-1*,aalib*,libcaca*,gd*,audiofile*,dbus*,esound*,libieee1284*,libogg*,libtheora*,libvorbis*,libcddb*,libsamplerate*,libraw1394*,v4l-utils*,liboil*,mpfr*,wavpack*,libcdio*,expat*,urwid*,neon*,pcre*,libmpc*,libsndfile*,libnotify*,fftw*,libarchive*,libksba*,pygobject*,libmcrypt*,libssh-*,libatasmart-*,libffi-*,pycurl-*"

whitelist_n="nmap*,links*,bind*,curl*,tcpdump*,openssh*,dhcp-*,libgcrypt*,ppp*,bluez*,wget*,iproute2*,wpa_supplicant*,iptables*,iptraf*,openvpn*,openssl*,rsync*,gpgme*,dnsmasq*,wireless-tools*,ipw*,vsftpd*,net-tools*,stunnel*,pth*,obex*,openobex*,rp-pppoe*,tcp_wrappers*,netpipes*,iputils*,libgpg*,telnet*,nc-*,ethtool*,rdist*,mtr*,tftp-hpa*,netkit-ftp*,whois*,zd1211*,bridge-utils*,portmap*,network-scripts*,inetd*,popa3d*,bsd-finger*,traceroute*,iw*,crda*,pssh*,biff+comsat*,icmpinfo*,rfkill*,idnkit*,libassuan*"
whitelist_n=$whitelist_n",httpd*,gnutls*,sendmail*,cyrus-sasl*,openldap-client*,nfs-utils*,procmail*,netwatch*,vlan*,netkit-routed*,netwrite*,gnupg-*,iftop-,mobile-broadband-provider-info-*,ca-certificates-*,libksba-*,gnupg2-*"

slacky_get() {
if [[ -z $1 ]]; then
  if [[ ! -f PACKAGES.TXT ]]; then
    wget http://repository.slacky.eu/slackware-13.0/PACKAGES.TXT
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
wget -N ftp://ftp.osuosl.org/pub/slackware/slackware${ARCH}-13.37/slackware${ARCH}/n/dhcpcd-5.2.11-*.txz # 56K - we need to downgrade for now because wicd doesn't work with the latest
wget -N http://packages.nimblex.net/nimblex/b43-firmware-5.100.138-fw-1.txz	# 145K
if [[ $ARCH = "" ]]; then
 wget -N http://packages.nimblex.net/nimblex/sshfs-fuse-2.3-i486-1.tgz		# 55K
 wget -N http://packages.nimblex.net/nimblex/glib2-2.33.1-i486-1.txz		# 3.1M
 wget -N http://packages.nimblex.net/nimblex/systemd-188-i486-1.txz		# 1.3M
 wget -N http://packages.nimblex.net/nimblex/grub2-2.00-slim-i486-1.txz		# 1.6M
 wget -N http://packages.nimblex.net/nimblex/libnih-1.0.3.txz			# 336K
 wget -N http://packages.nimblex.net/nimblex/atop-1.26-i486-1.tgz		# 113K
 wget -N http://packages.nimblex.net/nimblex/curlftpfs-0.9.2-i486-1.tgz		# 41K
 wget -N http://packages.nimblex.net/nimblex/ncdu-1.8-i486-1.tgz		# 28K
 wget -N http://packages.nimblex.net/nimblex/radvd-1.9.1-i486-1.tgz		# 71K
 wget -N http://packages.nimblex.net/nimblex/tdb-1.0.6-i486-1.tgz		# 50K
 wget -N http://packages.nimblex.net/nimblex/csync-0.49.9-i486-1.txz		# 88K
 wget -N $extrasrc/libraries/libasyncns/0.8/libasyncns-0.8-i486-3sl.txz 	# 23K
 wget -N $extrasrc/network/nss-mdns/0.10/nss-mdns-0.10-i486-6sl.txz		# 22K
 wget -N $extrasrc/libraries/libdaemon/0.14/libdaemon-0.14-i486-2sl.txz		# 25K
 wget -N $extrasrc/network/xl2tpd/1.2.8/xl2tpd-1.2.8-i686-1sl.txz		# 58K
 wget -N $extrasrc/system/ndiswrapper/1.56/ndiswrapper-1.56-i486-1sl.txz	# 102K
 wget -N $extrasrc/multimedia/transcode/1.1.5/transcode-1.1.5-i486-5sl.txz	# 1MB
 wget -N $extrasrc/utilities/cabextract/1.4/cabextract-1.4-i486-1sl.txz		# 59K
 wget -N $extrasrc/system/slapt-get/0.10.2m/slapt-get-0.10.2m-i486-1sl.txz	# 165K
 wget -N $extrasrc/libraries/libevent/2.0.11/libevent-2.0.11-i486-1sl.txz	# 181K
 wget -N $extrasrc/multimedia/vcdimager/0.7.24/vcdimager-0.7.24-i486-1sl.txz	# 304K
 wget -N $extrasrc/development/lua/5.1.4.3/lua-5.1.4.3-i486-1sl.txz		# 188K
 wget -N $extrasrc/system/fuseiso/20070708/fuseiso-20070708-i486-5sl.txz	# 25K
 wget -N $extrasrc/libraries/libnet/1.1.6/libnet-1.1.6-i486-2sl.txz		# 147K
 wget -N $extrasrc/network/ettercap/0.7.3/ettercap-0.7.3-i486-7sl.txz		# 400K
 wget -N $extrasrc/network/airpwn/1.4/airpwn-1.4-i486-4sl.txz			# 60K
 wget -N $extrasrc/utilities/bar/1.11.1/bar-1.11.1-i486-1sl.txz			# 37K
 wget -N $extrasrc/security/tomoyo-tools/2.3.0p2/tomoyo-tools-2.3.0p2-i486-1sl.txz # 100K
elif [[ $ARCH = "64" ]]; then
 wget -N $extrasrc/system/sshfs-fuse/2.3/sshfs-fuse-2.3-x86_64-1sl.txz		# 50K
 wget -N $extrasrc/utilities/bar/1.11.1/bar-1.11.1-x86_64-1sl.txz		# 50K
 wget -N $extrasrc/utilities/cabextract/1.3/cabextract-1.3-x86_64-1sl.txz	# 68K
 wget -N http://software.jaos.org/slackpacks/13.37-x86_64/slapt-get/slapt-get-0.10.2m-x86_64-1.tgz # 227K
 wget -N $extrasrc/libraries/libdaemon/0.14/libdaemon-0.14-x86_64-2sl.txz	# 27K
 wget -N $extrasrc/libraries/libevent/2.0.11/libevent-2.0.11-x86_64-1sl.txz	# 242K
 wget -N $extrasrc/multimedia/vcdimager/0.7.24/vcdimager-0.7.24-x86_64-1sl.txz	# 319K
 wget -N $extrasrc/development/lua/5.1.4/lua-5.1.4-x86_64-2sl.txz		# 214K
 wget -N $extrasrc/system/fuseiso/20070708/fuseiso-20070708-x86_64-1sl.txz	# 26K
 wget -N $extrasrc/libraries/libnet/1.1.6/libnet-1.1.6-x86_64-2sl.txz		# 152K
 wget -N $extrasrc/network/airpwn/1.4/airpwn-1.4-x86_64-1sl.txz			# 64K
 wget -N $extrasrc/utilities/bar/1.11.1/bar-1.11.1-x86_64-1sl.txz		# 50K
 wget -N $extrasrc/system/curlftpfs/0.9.2/curlftpfs-0.9.2-x86_64-1sl.txz	# 38K
fi
}

upgrade_packages() {
rm $SD/$NP-work/udev-182-i486-3.txz
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
sed -i 's/darkstar/nimblex/g' etc/rc.d/rc.M
#sed -i 's/LESS="-M"/LESS="-MR"/' etc/profile

# systemD related
ln -s /usr/lib/libffi.so.6.0.0 usr/lib/libffi.so.4
rm -f sbin/reboot && ln -s /bin/systemctl sbin/reboot
rm -f sbin/halt && ln -s /bin/systemctl sbin/halt
rm -r etc/mtab && ln -s /proc/self/mounts etc/mtab
sed -i '/lockdev 0775 root lock/'d usr/lib/tmpfiles.d/legacy.conf
echo "PACKAGE NAME:     udev-188" > var/log/packages/udev-188-i486-1

rm etc/slackware-version

rm boot/*
echo "nimblex" > etc/HOSTNAME
echo "NimbleX Linux." > etc/motd
echo "<html><body><h1>NimbleX is running your web server!</h1></body></html>" > srv/httpd/htdocs/index.html
echo "nameserver 8.8.8.8" > etc/resolv.conf
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

adjust-core() {
echo "You now have to adjust the startup script by hand."
echo "Adjust rc.M and add rc.nimblex for start"

chmod -x etc/rc.d/rc.sshd

# Syslinux section

}

copy-static() {
echo "Copying stuff from 06-NimbleX"
cp ../06-NimbleX/etc/issue* etc/
cp ../06-NimbleX/etc/dhcpd.conf etc/
cp ../06-NimbleX/etc/vsftpd.conf etc/
cp ../06-NimbleX/etc/localtime etc/
cp ../06-NimbleX/etc/bootchartd.conf etc/
cp ../06-NimbleX/etc/profile etc/
cp ../06-NimbleX/etc/profile.d/*.sh etc/profile.d/
cp ../06-NimbleX/etc/slapt-get/slapt-getrc etc/slapt-get/
cp ../06-NimbleX/etc/rc.d/rc.* etc/rc.d/
# cp ../06-NimbleX/usr/share/wallpapers/nimblex-wallpaper.jpg usr/share/wallpapers/
cp ../06-NimbleX/var/spool/mail/root var/spool/mail/root

cp ../06-NimbleX/etc/os-release etc/
cp ../06-NimbleX/lib/systemd/system/*.{service,socket} lib/systemd/system/
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
chroot . /usr/sbin/groupadd -g215 vboxusers 2> /dev/null
}


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
	  adjust-core
	  copy-static
	  run-ldconfig
	 ;;
	 "lzmfy" )
	  echo "...LZMFY"
	  mksquashfs $SD/$NP $SD/$NP.lzm -noappend -b 256k -no-xattrs
	 ;;
	 "world" )
	  echo "...DOWNLOADING"
	  downloadpkg
          upgrade_packages # This should be just temporary untill Slackware upgrades it
	  echo "...INSTALLING"
	  instpkg
	  clean-core
	  adjust-core
	  copy-static
	  run-ldconfig
	  echo "...LZMFY"
	  mksquashfs $SD/$NP $SD/$NP.lzm -noappend -b 256k -no-xattrs
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi

