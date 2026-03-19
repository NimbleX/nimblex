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

whitelist_a="grub-*,floppy-*"
blacklist_d="perl*,llvm-*,gcc-java-*,gcc-gnat-*,gcc-go-*,gcc-gfortran-*,rust-*"
whitelist_l="glibci-*,mpfr-*,db4-*,boost-*,python-packaging-*,python-pygments-*,python-docutils-*"
whitelist_ap="linuxdoc-tools*,texinfo*"

mkdir -p $NP $NP-work $NP-removed

downloadpkg() {
cd $SD/$NP-work
wget $WGET_OPTS -A "$whitelist_a" "$slacksrc"/a/*.txz
wget $WGET_OPTS -R "$blacklist_d" "$slacksrc"/d/*.txz
wget $WGET_OPTS -A "$whitelist_l" "$slacksrc"/l/*.txz
wget $WGET_OPTS -A "$whitelist_ap" "$slacksrc"/ap/*.txz

wget $WGET_OPTS http://packages.nimblex.net/nimblex/device-tree-compiler-1.7.2-x86_64-1.txz # 164K
wget $WGET_OPTS -N http://packages.nimblex.net/nimblex/pefile-2024.8.26-x86_64-1.txz           # 148K
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
#cp -a ../03-Libs${ARCH}-removed/devel/* .
cp -a ../04-Apps${ARCH}-removed/devel/* .
cp -a ../05-KDE${ARCH}-removed/devel/* .
}

fix_grub_font() {
cd $SD/$NP
ln -s /boot/grub/fonts/hack.pf2 usr/share/grub/unicode.pf2
}

run-ldconfig() {
echo "Running ldconfig and others chrooted inside $AUFS"

cd $SD && AUFS="aufs-temp" && mkdir -p $AUFS
mount -t aufs -o xino=/mnt/live/memory/aufs.xino,br:$NP none $AUFS
mount -t aufs -o remount,append:05-KDE${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:04-Apps${ARCH}=ro none $AUFS
#mount -t aufs -o remount,append:03-Libs${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:01-Core${ARCH}=ro none $AUFS

chroot $AUFS ldconfig
chroot $AUFS update-mime-database /usr/share/mime

umount $AUFS
rm -rf $NP/.wh..wh.*
}

SQUASH_OPT="-comp xz -noappend -b 256K -Xbcj x86 -no-xattrs"

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
      fix_grub_font
	  copy-removed
	  run-ldconfig
	 ;;
	 "lzmfy" )
	  echo "...LZMFY"
	  mksquashfs $NP $NP.lzm $SQUASH_OPT
	 ;;
	 "world" )
	  echo "...DOWNLOADING"
	  downloadpkg
	  echo "...INSTALLING"
	  instpkg
      fix_grub_font
	  copy-removed
	  run-ldconfig
	  echo "...LZMFY"
	  mksquashfs $NP $NP.lzm $SQUASH_OPT
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi
