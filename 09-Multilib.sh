#!/bin/bash
#bash +x
set -e

NP=`basename $0 | cut -d "." -f 1`

clean_download_install() {

rm -rf $NP $NP-removed
mkdir -p $NP $NP-work $NP-removed

for i in $EXCLUDE; do
	ROPT=" --exclude $i $ROPT"
	FOPT=" -name $i -or $FOPT"
done
FOPT=$FOPT" -size +30M"


rsync -ah --delete $ROPT --log-file=/var/log/rsync-alien.log --timeout=300 taper.alienbase.nl::mirrors/people/alien/multilib/current/ $NP-work/

find $NP-work/ $FOPT | xargs rm -r

installpkg -root $NP $NP-work/*.t?z
installpkg -root $NP $NP-work/slackware64-compat32/*-compat32/*.t?z

for i in $DELETE; do
	rm -r ${NP}/${i}
done

}

run-ldconfig() {
echo "Running ldconfig and others chrooted inside $AUFS"

AUFS="aufs-temp" && mkdir -p $AUFS
mount -t aufs -o xino=/mnt/live/memory/aufs.xino,br:$NP none $AUFS
mount -t aufs -o remount,append:07-Devel64=ro none $AUFS
mount -t aufs -o remount,append:05-KDE64=ro none $AUFS
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
 "min" )
  EXCLUDE="qt-compat32-* icu4c-compat32-* seamonkey-solibs-compat32-* lesstif-compat32-* gst-plugins-* gstreamer-compat32-* cairo-compat32-* libgphoto2-compat32-* cairo-compat32-* mesa-compat32-* libsamplerate-compat32-* audiofile-compat32-* openssl-solibs-compat32-* gcc-go-* gcc-gnat-* gcc-gfortran-* gcc-objc-* debug ap-compat32 n-compat32 ap-compat32 d-compat32 xap-compat32"
  DELETE="usr/lib/locale usr/lib64/locale usr/share/locale usr/doc"
  clean_download_install
  echo "...Minimum Multilib Setup"
 ;;
 "med" )
  clean_download_install
  echo "...Average Multilib Setup"
 ;;
 "max" )
  clean_download_install
  echo "...Fully Blown Multilib"
 ;;
esac

run-ldconfig

SQUASH_OPT="-comp xz -noappend -b 256K -Xbcj x86 -no-xattrs"
mksquashfs $NP $NP.lzm $SQUASH_OPT

echo -e "\n $0 \033[7m DONE \033[0m \n"

