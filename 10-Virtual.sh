#!/bin/bash
#bash +x
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`${ARCH} # NimbleX Package name
WGET_OPTS="${WGET_OPTS:--q -N}"

if [[ -f .ftp-credentials ]]; then
  . .ftp-credentials
  slacksrc="ftp://${USERNAME}:${PASSWORD}@${HOSTNAME}/Bogdan/packages/slackware${ARCH}/slackware${ARCH}"
else
  slacksrc="ftp://slackware.telecoms.bg/slackware/slackware${ARCH}-current/slackware${ARCH}"
fi

extrasrc="http://packages.nimblex.net/slacky${ARCH}"
nxsrc="http://packages.nimblex.net/nimblex"


downloadpkg() {
mkdir -p $NP $NP-work $NP-removed
cd $SD/$NP-work

if [[ $ARCH = "" ]]; then
 echo "We are not suporting 32bit for the virtualizaton functionality"
elif [[ $ARCH = "64" ]]; then
# wget $WGET_OPTS -N $nxsrc/acpica-20170531-x86_64-1.txz		# 741K
 wget $WGET_OPTS -N $nxsrc/drbd-utils-9.32.0-x86_64-1.txz  	# 612K
# wget $WGET_OPTS -N $nxsrc/leveldb-1.15.0-x86_64-1.txz         # 151K
 wget $WGET_OPTS -N $nxsrc/libvirt-10.10.0-x86_64-1.txz        # 8.0M
 wget $WGET_OPTS -N $nxsrc/libvirt-glib-5.0.0-x86_64-1.txz		# 300K
 wget $WGET_OPTS -N $nxsrc/libvirt-python-10.10.0-x86_64-1.txz # 295K
 wget $WGET_OPTS -N $nxsrc/qemu-10.2.2-x86_64-1.txz            # 27M
# wget $WGET_OPTS -N $nxsrc/libosinfo-0.3.1-x86_64-1.txz		# 339K
 wget $WGET_OPTS -N $nxsrc/spice-0.16.0-x86_64-1.txz           # 360K
 wget $WGET_OPTS -N $nxsrc/spice-gtk-0.42-x86_64-1.txz         # 496K
 wget $WGET_OPTS -N $nxsrc/spice-protocol-0.14.5-noarch-1.txz	# 24K
 wget $WGET_OPTS -N $nxsrc/openvswitch-utils-3.3.6-x86_64-1.txz	# 2.1M
 wget $WGET_OPTS -N $nxsrc/virt-manager-5.0.0-x86_64-1.txz     # 1.1M
 wget $WGET_OPTS -N $nxsrc/usbredir-0.14.0-x86_64-1.txz	    # 52K
 wget $WGET_OPTS -N $nxsrc/gtk-vnc-1.5.0-x86_64-1.txz		    # 198K
 wget $WGET_OPTS -N $nxsrc/docker-29.4.2-x86_64-1.txz		    # 20M
# wget $WGET_OPTS -N $nxsrc/vte3-0.44.2-x86_64-1.txz		    # 566K
fi
}

instpkg() {
for pkg in $SD/$NP-work/* ; do
   installpkg --root $SD/$NP $pkg
done
}

clean-virt() {
cd $SD/$NP
# Remove stuff we don't need
echo "Starting the core cleanup procedure ..."

rm -r usr/{doc,share/gtk-doc}

# Handle Man pages
mkdir -p ../$NP-removed/man_pages/usr/man/ && mv usr/man/* $_

# Handle locale
mkdir -p ../$NP-removed/locale/usr/share/locale/ && mv usr/share/locale/* $_

# Handle .h & .a files
mkdir -p ../$NP-removed/devel/usr/include/ && mv usr/include/* $_

mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/ && mv usr/lib${ARCH}/*.a $_

mkdir -p usr/lib/udev && mv lib/udev/* usr/lib/udev/ 2>/dev/null || true
sed -i 's|/lib/udev/|/usr/lib/udev/|g' usr/lib/udev/rules.d/*.rules 2>/dev/null || true
}

copy-static() {
echo "Copying stuff from 06-NimbleX"
cp ../06-NimbleX/etc/issue* etc/
mkdir -p etc/systemd/system/multi-user.target.wants
mkdir -p usr/lib/systemd/system
cp -a ../06-NimbleX/usr/lib/systemd/system/virt*.service usr/lib/systemd/system/
cp -a ../06-NimbleX/usr/lib/systemd/system/virt*.socket usr/lib/systemd/system/
# libvirt is now modular. We don't need the next one
#cp -a ../06-NimbleX/usr/lib/systemd/system/libvirtd*.service usr/lib/systemd/system/
#cp -a ../06-NimbleX/usr/lib/systemd/system/libvirtd*.socket usr/lib/systemd/system/
ln -s /usr/lib/systemd/system/libvirtd.service etc/systemd/system/multi-user.target.wants/libvirtd.service
ln -s /usr/lib/systemd/system/virtlogd.service etc/systemd/system/multi-user.target.wants/virtlogd.service
ln -s /usr/lib/systemd/system/virtqemud.service etc/systemd/system/multi-user.target.wants/virtqemud.service
ln -s /usr/lib/systemd/system/virtnetworkd.service etc/systemd/system/multi-user.target.wants/virtnetworkd.service
ln -s /usr/lib/systemd/system/virtstoraged.service etc/systemd/system/multi-user.target.wants/virtstoraged.service
}

run-caches() {
cd $SD && AUFS="aufs-temp"
echo "Rebuilding caches chrooted inside $AUFS"

mount | grep aufs-temp && umount aufs-temp
mkdir -p $AUFS
mount -t aufs -o xino=/mnt/live/memory/aufs.xino,br:$NP none $AUFS
mount -t aufs -o remount,append:07-Devel${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:05-KDE${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:04-Apps${ARCH}=ro none $AUFS
#mount -t aufs -o remount,append:03-Libs${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:01-Core${ARCH}=ro none $AUFS

chroot $AUFS ldconfig
chroot $AUFS fc-cache
chroot $AUFS update-mime-database /usr/share/mime
chroot $AUFS update-desktop-database -q /usr/share/applications
chroot $AUFS gio-querymodules /usr/lib${ARCH}/gio/modules
chroot $AUFS update-gdk-pixbuf-loaders
chroot $AUFS glib-compile-schemas /usr/share/glib-2.0/schemas/

umount $AUFS
rm -rf $NP/.wh..wh.*
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
	  clean-virt
	  copy-static
	  run-caches
	 ;;
	 "lzmfy" )
	  echo "...LZMFY"
	  mksquashfs $SD/$NP $SD/$NP.lzm $SQUASH_OPT
	 ;;
	 "world" )
	  echo "...CLEANING"
	  rm -r $NP && echo $NP deleted
	  rm -r $NP-work && echo $NP-work deleted
	  rm -r $NP-removed && echo $NP-removed deleted
	  echo "...DOWNLOADING"
	  downloadpkg
	  echo "...INSTALLING"
	  instpkg
	  clean-virt
	  copy-static
	  run-caches
	  echo "...LZMFY"
	  mksquashfs $SD/$NP $SD/$NP.lzm $SQUASH_OPT
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi

