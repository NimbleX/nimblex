#!/bin/bash
#bash +x
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`${ARCH} # NimbleX Package name
slacksrc="ftp://ftp.rdsbv.ro/mirrors/slackware/slackware${ARCH}-current/slackware${ARCH}"
slacksrc="ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware${ARCH}-current/slackware${ARCH}"
extrasrc="http://repository.slacky.eu/slackware${ARCH}-13.37/"

ToBeAdded=(ipcalc madwifi perl)


blacklist_a="kernel-[ghm]*,mkinitrd*,elvis*,floppy*,mtx*,tcsh*,ed*,sharutils*,loadlin*,devs*,apmd*"
blacklist_ap="ghostscript*,hplip*,mysql*,vim*,linuxdoc*,man*,zsh*,groff*,gutenprint*,a2ps*,texinfo*,ksh93*,jed*,enscript*,cupsddk*,joe*,ispell*,jove*"
whitelist_ap="mc*,flac*,rpm*,cdrtools*,screen*,sox*,sqlite*,nano*,xfsdump*,ntfsprogs*,lsof*,diffutils*,sysstat*,gphoto2*,vorbis-tools*,dc3dd*,lm_sensors*,sudo*,dvd+rw-tools*,cdparanoia*,bc*,ash*,normalize*,madplay*,aumix*,slackpkg*,dmidecode*,seejpeg*,bpe*,pm-utils*,most*,at*,dmapi*,lsscsi*,vbetool*,rzip*,diffstat*,libx86*,radeontool*"
whitelist_l="ncurses*,libgphoto2*,parted*,taglib*,apr*,fuse*,libusb*,zlib*,lzo*,libmad*,libtermcap*,libcap*,gdbm*,popt*,libao*,libid3tag*,mm*,libmowgli*,libmcs*,libaio*,alsa*,libnl*,ConsoleKit*,libpcap*,libzip*"
whitelist_l=$whitelist_l",gmp*,libidn*,glib*,aalib*,libcaca*,gd*,audiofile*,dbus*,esound*,libieee1284*,libogg*,libtheora*,libvorbis*,libcddb*,libsamplerate*,libraw1394*,v4l-utils*,liboil*,mpfr*,wavpack*,libcdio*,expat*,urwid*,neon*,pcre*,libmpc*,libsndfile*,libnotify*,fftw*,libarchive*,libksba*,pygobject*,libmcrypt*"
blacklist_l="glibc*"

whitelist_n="nmap*,links*,bind*,curl*,tcpdump*,openssh*,dhcp*,libgcrypt*,ppp*,bluez*,wget*,iproute2*,wpa_supplicant*,iptables*,iptraf*,openvpn*,openssl*,rsync*,gpgme*,iwlwifi*,dnsmasq*,wireless-tools*,ipw*,vsftpd*,net-tools*,stunnel*,pth*,obex*,openobex*,rp-pppoe*,tcp_wrappers*,netpipes*,iputils*,libgpg*,telnet*,nc-*,ethtool*,rdist*,mtr*,tftp-hpa*,netkit-ftp*,whois*,zd1211*,dhcpcd*,bridge-utils*,portmap*,network-scripts*,inetd*,popa3d*,bsd-finger*,traceroute*,iw*,crda*,pssh*,biff+comsat*,icmpinfo*,rt61*,rt71w*,rt28*,rfkill*,idnkit*,libassuan*"
whitelist_n=$whitelist_n",httpd*,gnutls*,sendmail*,cyrus-sasl*,openldap-client*,nfs-utils*,procmail*,netwatch*,vlan*,netkit-routed*,netwrite*,gnupg-*"

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

extra="grub,chillispot,clamav,scanssh,nrg2iso,mdf2iso"
extra_lib=""

mkdir -p $NP $NP-work $NP-removed

downloadpkg() {
cd $SD/$NP-work
wget "$slacksrc"/a/*.tgz				# gzip, tar, xz, pkgtools 1.2MB
wget -R "$blacklist_a" "$slacksrc"/a/*.txz			# 23.9	MB
wget -R "$blacklist_ap" "$slacksrc"/ap/*.t[g-x]z		# 7	MB
wget -A "$whitelist_l" -R "$blacklist_l" "$slacksrc"/l/*.txz	# 7.6	MB
wget -A "$whitelist_n" "$slacksrc"/n/*.txz			# 17.2	MB

#wget ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware-current/extra/grub/grub-0.97-i486-8.txz

echo Use the script that downloads slacky packages by name because this is a bit to much to maintain

wget $slacksrc/d/python-2.*.txz # 11500K
wget $slacksrc/d/perl-5.*.txz # 14500K - should be 5.3M after crap is deleted
wget $slacksrc/d/libtool-2.*.txz # 365K
wget $slacksrc/tcl/tcl-8.*.txz # 1655K
wget ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware${ARCH}-current/extra/wicd/wicd-1.*.txz # 347K
if [[ $ARCH = "" ]]; then
# wget http://repository.slacky.eu/slackware${ARCH}-13.0/system/sshfs/2.2/sshfs-2.2-i486-3kc.txz # 40K
# wget http://repository.slacky.eu/slackware${ARCH}-13.0/network/ettercap/0.7.3/ettercap-0.7.3-i686-4sv.txz # 460K
 wget http://node3.nimblex.net/Download/slackware-current/sshfs-fuse-2.2-i486-1_SBo.tgz
 wget http://node3.nimblex.net/Download/slackware-current/ettercap-NG-0.7.3-i486-2_SBo.tgz
 wget http://repository.slacky.eu/slackware${ARCH}-13.1/libraries/libasyncns/0.8/libasyncns-0.8-i486-1sl.txz # 23K
 wget $extrasrc/network/nss-mdns/0.10/nss-mdns-0.10-i486-6sl.txz # 22K
 wget $extrasrc/libraries/libdaemon/0.14/libdaemon-0.14-i486-2sl.txz #25K
 wget $extrasrc/network/xl2tpd/1.2.8/xl2tpd-1.2.8-i686-1sl.txz # 58K
 #wget http://repository.slacky.eu/slackware${ARCH}-13.1/network/clamav/0.96.5/clamav-0.96.5-i486-1sl.txz # HUGE > 29MB
 wget $extrasrc/system/ndiswrapper/1.56/ndiswrapper-1.56-i486-1sl.txz # 102K
 wget $extrasrc/multimedia/transcode/1.1.5/transcode-1.1.5-i486-5sl.txz # 1MB
 wget $extrasrc/utilities/cabextract/1.4/cabextract-1.4-i486-1sl.txz # 59K
 wget $extrasrc/system/slapt-get/0.10.2j/slapt-get-0.10.2j-i486-1sl.txz # 165K
 wget $extrasrc/libraries/libevent/2.0.11/libevent-2.0.11-i486-1sl.txz # 181K
 wget $extrasrc/multimedia/vcdimager/0.7.24/vcdimager-0.7.24-i486-1sl.txz # 304K
 wget $extrasrc/development/lua/5.1.4.3/lua-5.1.4.3-i486-1sl.txz # 188K
 wget $extrasrc/system/fuseiso/20070708/fuseiso-20070708-i486-5sl.txz # 25K
 wget $extrasrc/libraries/libnet/1.1.5/libnet-1.1.5-i486-2sl.txz # 140K
 wget $extrasrc/network/airpwn/1.4/airpwn-1.4-i486-4sl.txz # 60K
 wget $extrasrc/security/tomoyo-tools/2.3.0p2/tomoyo-tools-2.3.0p2-i486-1sl.txz # 100K
elif [[ $ARCH = "64" ]]; then
 wget $extrasrc/utilities/bar/1.11.1/bar-1.11.1-x86_64-1sl.txz # 50K
 wget $extrasrc/utilities/cabextract/1.3/cabextract-1.3-x86_64-1sl.txz # 68K
 wget $extrasrc/system/slapt-get/0.10.2e/slapt-get-0.10.2e-x86_64-1sl.txz # 158K FIXME
 wget $extrasrc/libraries/libdaemon/0.14/libdaemon-0.14-x86_64-1sl.txz #25K FIXME
 wget $extrasrc/libraries/libevent/2.0.11/libevent-2.0.11-x86_64-1sl.txz # 242K
 wget $extrasrc/multimedia/vcdimager/0.7.23/vcdimager-0.7.23-x86_64-2sl.txz # FIXME
 wget $extrasrc/development/lua/5.1.4/lua-5.1.4-x86_64-2sl.txz # 214K
fi
}

upgrade_packages() {
rm $SD/$NP-work/util-linux-2.19-i486-1.txz && cp $SD/../systemd-project/util-linux-2.20-i486-1.txz $SD/$NP-work/
rm $SD/$NP-work/udev-165-i486-2.txz && cp $SD/../systemd-project/udev-175-i486-1.txz $SD/$NP-work/
rm $SD/$NP-work/dbus-1.4.1-i486-1.txz && cp $SD/../systemd-project/dbus-1.4.6-i486-1.txz $SD/$NP-work/
rm $SD/$NP-work/ConsoleKit-0.4.3-i486-1.txz && cp $SD/../systemd-project/ConsoleKit-0.4.4-i486-1.txz $SD/$NP-work/
cp $SD/../systemd-project/systemd-37-i486-1.txz $SD/$NP-work/
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
#ln -s usr/lib/libmpfr.so usr/lib/libmpfr.so.1  # This should be temporary

chmod -x etc/rc.d/rc.pcmcia
chmod -x etc/rc.d/rc.inetd
chmod +x etc/rc.d/rc.bluetooth
sed 's/darkstar/nimblex/g' etc/hosts > etc/hosts.tmp && mv etc/hosts.tmp etc/hosts
sed 's/darkstar/nimblex/g' etc/rc.d/rc.M > etc/rc.d/rc.M.tmp && mv etc/rc.d/rc.M.tmp etc/rc.d/rc.M && chmod +x etc/rc.d/rc.M

rm etc/slackware-version

rm boot/*
echo "nimblex" > etc/HOSTNAME
echo "NimbleX Linux." > etc/motd
echo "<html><body><h1>NimbleX is running your web server!</h1></body></html>" > srv/httpd/htdocs/index.html
echo "nameserver 208.92.232.30" > etc/resolv.conf
rm -r media/* mnt/*
rm -r usr/{doc,share/gtk-doc}
rm usr/info/*
rm -r usr/share/mc/{help,hints}  # ~300KB
rm -r usr/share/zenmap/pixmaps # 270KB
rm -r var/www/htdocs/manual # 730KB
rm usr/share/sounds/alsa/* # 730KB
rm usr/bin/omshell   # 470KB
rm usr/sbin/dhcrelay # 480KB
rm sbin/dhclient*    # 512KB
rm sbin/*.static     # 1.4MB

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

mkdir -p ../$NP-removed/devel/lib${ARCH}/ && mv lib${ARCH}/*.a $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/ && mv usr/lib${ARCH}/*.a $_

# Slim down Python some more because it's a HUGE bitch
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.6/ && mv usr/lib${ARCH}/python2.6/test $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.6/bsddb/ && mv usr/lib${ARCH}/python2.6/bsddb/test $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.6/config/ && mv usr/lib${ARCH}/python2.6/config/*.a $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.6/ctypes/ && mv usr/lib${ARCH}/python2.6/ctypes/test $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.6/distutils/ && mv usr/lib${ARCH}/python2.6/distutils/tests $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.6/email/ && mv usr/lib${ARCH}/python2.6/email/test $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.6/json/ && mv usr/lib${ARCH}/python2.6/json/tests $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.6/lib2to3/ && mv usr/lib${ARCH}/python2.6/lib2to3/tests $_
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/python2.6/sqlite3/ && mv usr/lib${ARCH}/python2.6/sqlite3/test $_
rm usr/lib${ARCH}/python2.6/distutils/command/wininst*

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
# WICD section

# Syslinux section

# clamav section

}

copy-static() {
echo "Copying stuff from 06-NimbleX"
cp ../06-NimbleX/etc/issue* etc/
cp ../06-NimbleX/etc/dhcpd.conf etc/
cp ../06-NimbleX/etc/vsftpd.conf etc/
cp ../06-NimbleX/etc/localtime etc/
cp ../06-NimbleX/etc/bootchartd.conf etc/
cp ../06-NimbleX/etc/slapt-get/slapt-getrc etc/slapt-get/
cp ../06-NimbleX/etc/rc.d/rc.* etc/rc.d/
# cp ../06-NimbleX/usr/share/wallpapers/nimblex-wallpaper.jpg usr/share/wallpapers/
cp ../06-NimbleX/var/spool/mail/root var/spool/mail/root

if [[ $ARCH = "" ]]; then
cp -a ../06-NimbleX/sbin/* sbin/
cp -a ../06-NimbleX/usr/bin/ usr/
cp -a ../06-NimbleX/usr/lib/ usr/
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
	  mksquashfs $SD/$NP $SD/$NP.lzm -noappend -b 256k
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
	  mksquashfs $SD/$NP $SD/$NP.lzm -noappend -b 256k
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi

