#!/bin/bash
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`${ARCH} # NimbleX Package name
LIST="FILELIST.TXT"
SRC="http://darkstar.ist.utl.pt/slackware/addon/slacky/slackware${ARCH}-13.37"
SRC="http://packages.nimblex.net/slacky${ARCH}"

mkdir -p $NP $NP-work $NP-removed/usr/{lib${ARCH},share}

whitelist_slacky_14=(gssdp gupnp SDL_gfx libgsm mp4v2 faac schroedinger xvidcore lame speex-1.2rc1 dirac libdc1394 libsigc++ cairomm glibmm pangomm atkmm gtkmm celt enca-1 libmodplug x264 libvpx opus utvideo opencore-amr ffmpeg-1.0 libmspack libdvdcss dvdauthor libdv-1 libiec61883 id3lib faad2 libavc1394 recordmydesktop fdesktoprecorder libssh2 libmpcdec libshout libaacplus twolame vo-aacenc vo-amrwbenc libquicktime mjpegtools libxml++ libffado jack-audio-connection-kit openal-soft flash-player-plugin unrar libebml libmatroska ladspa_sdk libbluray libdca libdvbpsi rtmpdump libvdpau ftgl exif libimobiledevice libxavs libaacplus libmpeg2 libtar libkate libtiger xosd libass libupnp goom soundtouch libsidplay gst-ffmpeg gst-plugins-ugly imlib2 goffice8 wv geoclue ORBit2 zope.interface)

downloadpkg() {
rm -f $LIST && wget $SRC/$LIST
cd $SD/$NP-work
for package in $(seq 0 $((${#whitelist_slacky_14[*]} -1))); do
TXZn=(`cat ../$LIST | awk '/\.txz$/ {print $9}' | grep -w "${whitelist_slacky_14[$package]}" | cut -b 2-`)
  for i in $(seq 0 $((${#TXZn[*]} -1))); do
    wget -N $SRC${TXZn[i]}
  done
done

}

instpkg() {
for pkg in $SD/$NP-work/* ; do
   installpkg --root $SD/$NP $pkg
done
}

clean-Lib() {
cd $SD/$NP
echo "Removing SOME of the most usless crap (doc,man,gtk-doc)"
rm -r usr/doc
rm -rf usr/share/{doc,gtk-doc,devhelp}
rm -r usr/share/imlib2/data/images/*.png
rm -f usr/lib/python2.6/site-packages/mlt_wrap.o  # Only if we decide to keep mlt which takes ~700K

echo "Moving other usless crap (include/man/locale)"

# Handle Man pages
mkdir -p ../$NP-removed/man_pages/usr/man/
mv usr/man/* ../$NP-removed/man_pages/usr/man/
# Handle locale
mkdir -p ../$NP-removed/locale/usr/share/locale/
mv usr/share/locale/* ../$NP-removed/locale/usr/share/locale/
# Handle .h & .a files
mkdir -p ../$NP-removed/devel/usr/include/
mv usr/include/* ../$NP-removed/devel/usr/include/
mkdir -p ../$NP-removed/devel/usr/lib${ARCH}/
mv usr/lib${ARCH}/*.a ../$NP-removed/devel/usr/lib${ARCH}/

# Think of moving "usr/share/imlib2/data/fonts"

}


run-ldconfig() {
cd $SD && AUFS="aufs-temp"
echo "Running ldconfig and others chrooted inside $AUFS"

mkdir -p $AUFS
mount -t aufs -o xino=/mnt/live/memory/aufs.xino,br:03-Libs${ARCH} none $AUFS
mount -t aufs -o remount,append:02-Xorg${ARCH}-3D=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:01-Core${ARCH}=ro none $AUFS

chroot $AUFS ldconfig

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
	  clean-Lib
	  run-ldconfig
	 ;;
	 "lzmfy" )
	  echo "...LZMFY"
	  rm -f $NP.lzm
	  mksquashfs $NP $NP.lzm $SQUASH_OPT
	 ;;
	 "world" )
	  echo "...DOWNLOADING"
	  downloadpkg
	  echo "...INSTALLING"
	  instpkg
	  clean-Lib
	  run-ldconfig
	  echo "...LZMFY"
	  rm -f $NP.lzm
	  mksquashfs $NP $NP.lzm $SQUASH_OPT
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi
