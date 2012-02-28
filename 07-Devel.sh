#!/bin/bash
#bash +x
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`${ARCH} # NimbleX Package name
slacksrc="ftp://ftp.rdsbv.ro/mirrors/slackware/slackware${ARCH}-current/slackware${ARCH}"
slacksrc="ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware${ARCH}-current/slackware${ARCH}"

blacklist_d="perl*,python*"
whitelist_l="glibc*,mpfr*"
whitelist_ap="linuxdoc-tools*"

mkdir -p $NP $NP-work $NP-removed

downloadpkg() {
cd $SD/$NP-work
wget -R "$blacklist_d" "$slacksrc"/d/*.txz
wget -A "$whitelist_l" "$slacksrc"/l/*.txz
wget -A "$whitelist_ap" "$slacksrc"/ap/*.txz
}

instpkg() {
for pkg in $SD/$NP-work/* ; do
   installpkg --root $SD/$NP $pkg
done
}

copy-removed() {
cd $SD/$NP
echo "Adding stuff removed from the other packages"
cp -a ../01-Core${ARCH}-removed/devel/* .
cp -a ../02-Xorg${ARCH}-removed/devel/* .
cp -a ../03-Libs${ARCH}-removed/devel/* .
cp -a ../04-Apps${ARCH}-removed/devel/* .
cp -a ../05-KDE${ARCH}-removed/devel/* .
}

run-ldconfig() {
echo "Running ldconfig and others chrooted inside $AUFS"

cd $SD && AUFS="aufs-temp" && mkdir -p $AUFS
mount -t aufs -o br:$NP none $AUFS
mount -t aufs -o remount,append:05-KDE${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:04-Apps${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:03-Libs${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg${ARCH}-3D=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:01-Core${ARCH}=ro none $AUFS

chroot $AUFS ldconfig

umount $AUFS

}


if [[ -z $1 ]]; then
	echo "Tell me what to do"
	echo "You options are: clean download install lzmfy"
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
	  copy-removed
	  run-ldconfig
	 ;;
	 "lzmfy" )
	  echo "...LZMFY"
	  mksquashfs $NP $NP.lzm -noappend -b 256k
	 ;;
	 "world" )
	  echo "...DOWNLOADING"
	  downloadpkg
	  echo "...INSTALLING"
	  instpkg
	  copy-removed
	  run-ldconfig
	  echo "...LZMFY"
	  mksquashfs $NP $NP.lzm -noappend -b 256k
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi
