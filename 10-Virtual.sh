#!/bin/bash
#bash +x
set -e

. .ftp-credentials

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

extrasrc="http://packages.nimblex.net/slacky${ARCH}"
nxsrc="http://packages.nimblex.net/nimblex"


downloadpkg() {
mkdir -p $NP $NP-work $NP-removed
cd $SD/$NP-work

if [[ $ARCH = "" ]]; then
 echo "We are not suporting 32bit for the virtualizaton functionality"
elif [[ $ARCH = "64" ]]; then
 wget -N $nxsrc/acpica-20170531-x86_64-1.txz		# 741K
 wget -N $nxsrc/drbd-utils-8.9.2-x86_64-1.txz		# 182K
 wget -N $slacksrc/l/gobject-introspection-1.58.3-x86_64-1.txz	# 1.1M
 wget -N $slacksrc/l/libedit-20181209_3.1-x86_64-1.txz	# 101K
 wget -N $nxsrc/leveldb-1.9.0-x86_64-1.txz		# 160K
 wget -N $nxsrc/libvirt-3.9.0-x86_64-1.txz		# 9.3M
 wget -N $nxsrc/libvirt-glib-1.0.0-x86_64-1.txz		# 300K
 wget -N $nxsrc/libvirt-python-3.9.0-x86_64-1.txz	# 215K
 wget -N $nxsrc/pygobject3-3.14.0-x86_64-1.txz		# 250K
 wget -N $nxsrc/qemu-2.10.1-x86_64-1.txz		# 12M
 wget -N $nxsrc/libosinfo-0.3.1-x86_64-1.txz		# 339K
 wget -N $nxsrc/spice-0.14.0-x86_64-1.txz		# 558K
 wget -N $nxsrc/spice-gtk-0.33-x86_64-1.txz		# 470K
 wget -N $nxsrc/spice-protocol-0.12.13-noarch-1.txz	# 24K
 wget -N $nxsrc/ceph-10.2.2-x86_64-1.txz		# 272M
 wget -N $nxsrc/openvswitch-utils-2.8.1-x86_64-1.txz	# 1.8M
 wget -N $nxsrc/virt-manager-1.4.0-x86_64-1.txz		# 1M
 wget -N $nxsrc/usbredir-0.7.1-x86_64-1.txz		# 50K
 wget -N $nxsrc/gtk-vnc-0.5.4-x86_64-2.txz		# 176K
 wget -N $nxsrc/vte3-0.44.2-x86_64-1.txz		# 566K
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
}

copy-static() {
echo "Copying stuff from 06-NimbleX"
cp ../06-NimbleX/etc/issue* etc/
}

run-ldconfig() {
echo "Running ldconfig and others chrooted"
chroot . ldconfig
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
#	  copy-static
#	  run-ldconfig
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
#	  copy-static
#	  run-ldconfig
	  echo "...LZMFY"
	  mksquashfs $SD/$NP $SD/$NP.lzm $SQUASH_OPT
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi

