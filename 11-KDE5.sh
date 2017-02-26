#!/bin/bash
#set -x
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`

if [[ -f .ftp-credentials ]]; then
  . .ftp-credentials
  slacksrc="ftp://${USERNAME}:${PASSWORD}@${HOSTNAME}/Bogdan/packages/slackware${ARCH}/slackware${ARCH}"
  kde5src="ftp://${USERNAME}:${PASSWORD}@${HOSTNAME}/Bogdan/packages/kde/current/latest/`uname -m`"
else
  slacksrc="ftp://slackware.telecoms.bg/slackware/slackware${ARCH}-current/slackware${ARCH}"
  kde5src="ftp://alien.slackbook.org/alien/ktown/current/latest/`uname -m`"
fi

blacklist_kde=""
whitelist_l="clucene*,soprano*,qimageblitz*,strigi*,phonon-*,redland*,qca*,liblastfm*,libxklavier*,poppler*,libtiff*,libspectre*,libwnck*,attica*,eggdbus*,ebook-tools*,libdiscid*,shared-desktop-ontologies*,libiodbc*,herqq-*,libbluedevil-*,xapian-core-*,NOTYET_akonadi*"

mkdir -p $NP-work $NP $NP-removed/man_pages/usr/man $NP-removed/locale/usr/share/locale $NP-removed/devel/usr/{include,lib${ARCH}}

downloadpkg() {

#for i in $EXCLUDE; do
#	ROPT=" --exclude $i $ROPT"
#	FOPT=" -name $i -or $FOPT"
#done
#
#rsync -ah --delete $ROPT --log-file=/var/log/rsync-alien.log --timeout=300 bear.alienbase.nl::mirrors/alien-kde/current/latest/x86_64 $SD/$NP-work/


cd $SD/$NP-work
wget -N -R "$blacklist_kde" "$kde5src"/deps/*.txz
wget -N -R "$blacklist_kde" "$kde5src"/deps/telepathy/*.txz
wget -N -R "$blacklist_kde" "$kde5src"/kde/plasma/*.txz
wget -N -R "$blacklist_kde" "$kde5src"/kde/plasma-extra/*.txz
wget -N -R "$blacklist_kde" "$kde5src"/kde/telepathy/*.txz
wget -N -R "$blacklist_kde" "$kde5src"/kde/frameworks/*.txz
wget -N -R "$blacklist_kde" "$kde5src"/kde/applications/*.txz
wget -N -R "$blacklist_kde" "$kde5src"/kde/applications-extra/*.txz
wget -N -R "$blacklist_kde" "$kde5src"/kde/kdepim/*.txz
wget -N -R "$blacklist_kde" "$kde5src"/kde/kde4/*.txz
wget -N -R "$blacklist_kde" "$kde5src"/kde/kde4-extragear/*.txz
wget -N -A "$whitelist_l" "$slacksrc"/l/*.txz

}

instpkg() {

rm -rf $NP $NP-removed

for pkg in $SD/$NP-work/* ; do
   installpkg --root $SD/$NP $pkg
done                                                                                                                                                                                                                                                                           

}

clean-KDE() {
cd $SD/$NP

ln -s /etc/X11/xinit/xinitrc.plasma etc/X11/xinit/xinitrc

}

run-ldconfig() {
echo "Running ldconfig and others chrooted inside $AUFS"

AUFS="aufs-temp" && mkdir -p $AUFS
mount -t aufs -o xino=/mnt/live/memory/aufs.xino,br:$NP none $AUFS
mount -t aufs -o remount,append:04-Apps64=ro none $AUFS
mount -t aufs -o remount,append:03-Libs64=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg64-3D=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg64=ro none $AUFS
mount -t aufs -o remount,append:01-Core64=ro none $AUFS

chroot $AUFS ldconfig

umount $AUFS
rm -rf $NP/.wh..wh.*
}



case $1 in
 "clean" )
   echo "...CLEANING"
   rm -r $NP && echo $NP deleted
   rm -r $NP-work && echo $NP-work deleted
   rm -r $NP-removed && echo $NP-removed deleted
 ;;
 "min" )
  EXCLUDE="qt-compat32-* icu4c-compat32-* seamonkey-solibs-compat32-* lesstif-compat32-* gst-plugins-* gstreamer-compat32-* cairo-compat32-* libgphoto2-compat32-* cairo-compat32-* mesa-compat32-* libsamplerate-compat32-* audiofile-compat32-* openssl-solibs-compat32-* gcc-go-* gcc-gnat-* gcc-gfortran-* gcc-objc-* debug ap-compat32 n-compat32 ap-compat32 d-compat32 xap-compat32"
  clean_download_install
  echo "...Minimum KDE5 Setup"
 ;;
 "med" )
  downloadpkg
  instpkg
  clean-KDE
  echo "...Average KDE5 Setup"
 ;;
 "max" )
  clean_download_install
  echo "...Fully KDE5 Multilib"
 ;;
esac

#run-ldconfig

SQUASH_OPT="-comp xz -noappend -b 256K -Xbcj x86 -no-xattrs"
mksquashfs $SD/$NP $SD/$NP.lzm $SQUASH_OPT

echo -e "\n $0 \033[7m DONE \033[0m \n"

