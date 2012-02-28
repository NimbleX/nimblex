#!/bin/bash
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`${ARCH} # NimbleX Package name
LIST="FILELIST.TXT"
SRC="http://darkstar.ist.utl.pt/slackware/addon/slacky/slackware${ARCH}-13.37"

mkdir -p $NP $NP-work $NP-removed/usr/{lib${ARCH},share}

whitelist_slacky_l37=(a52dec cairo-perl cairomm gc glitz gssdp libsoup gupnp SDL_gfx SDL_Pango libgsm faac openjpeg schroedinger x264 xvidcore lame speex-1.2rc1 dirac libdc1394 libsigc glibmm pangomm imlib2 ffmpeg-0.8 libmspack portaudio dvdauthor videotrans libdv-1 dvgrab libiec61883 faad2 libavc1394 recordmydesktop gtkmm atkmm opencore-amr libcue libmms libmpcdec libshout unrar mjpegtools jack-audio-connection-kit celt liblo libquicktime openal-soft libgnomecanvas libwps libwpg flash-player-plugin zope.interface wildmidi qjson libebml libmatroska ladspa_sdk libva libvpx libbluray libdvdnav libdvdcss libdca libdvbpsi rtmpdump libvdpau libbs2b vo-aacenc vo-amrwbenc ftgl enca-1 libcanberra orc exif oxygen-gtk qtcurve twolame usbmuxd libxavs mlt-0.7 libmpdclient libaacplus libmpeg2 libtar libssh2 libkate libtiger xosd libass libupnp goom)

whitelist_slacky_ln=(a52dec cairo-perl cairomm gc orbit2 gconf giblib glitz gssdp libsoup gupnp sdl_gfx sdl_pango ilbc libgsm libusb1 faac amrwb amrnb openjpeg schroedinger x264 xvidcore lame speex-1.2rc1 dirac libdc1394 libsigc glibmm pangomm imlib2 ffmpeg libmspack portaudio dvdauthor videotrans libdv dvgrab libiec61883 faad2 libavc1394 recordmydesktop gtkmm opencore-amr libcue libmms libmpcdec libshout unrar mjpegtools jack-audio-connection-kit celt liblo libquicktime openal-soft libgnomecanvas libwps libwpg flash-player-plugin zope.interface wildmidi qjson libminizip libebml libmatroska tremor ladspa_sdk libva libvpx sound-theme-freedesktop ftgl- libcanberra orc exif oxygen-gtk)

downloadpkg() {
rm -f $LIST && wget $SRC/$LIST
cd $SD/$NP-work
for package in $(seq 0 $((${#whitelist_slacky_l37[*]} -1))); do
TXZn=(`cat ../$LIST | awk '{print $9}' | grep ".txz$" | grep -w "${whitelist_slacky_l37[$package]}" | cut -b 2-`)
  for i in $(seq 0 $((${#TXZn[*]} -1))); do
    wget $SRC${TXZn[i]}
  done
done

# We will have to take some of them manually from a different location
if [[ $ARCH = "" ]]; then
 echo QTCurve is in the slackware 13.37 repo
elif [[ $ARCH = "64" ]]; then
 wget http://repository.slacky.eu/slackware64-13.1/desktop/qtcurve/1.5.0/qtcurve-1.5.0-x86_64-1sl.txz
fi

echo DELETEing gst-ffmpeg, gconf-editor, gtk-recordmydesktop and maybe other crap
rm -f gst-ffmpeg*.txz
rm -f gconf-editor*.txz
rm -f gtk-recordmydesktop*.txz
}

instpkg() {
for pkg in $SD/$NP-work/* ; do
   installpkg --root $SD/$NP $pkg
done
}

clean-Lib() {
cd $SD/$NP
echo "Removing SOME of the most usless crap (doc,man,gtk-doc)"
rm -rf usr/doc
rm -rf usr/share/{doc,gtk-doc,devhelp,gtkmm-2.4,gnome/html,applications/gconf-cleaner.desktop}
rm -rf usr/share/imlib2/data/images/*.png
rm -rf usr/bin/gtkmm-demo
rm -rf usr/share/sounds/freedesktop/stereo/audio-*
rm -f usr/lib/python2.6/site-packages/mlt_wrap.o  # Only if we decide to keep mlt which take ~700K
# Clean some of the small stuff too
#rm -rf usr/share/applications/gconf-cleaner.desktop
#rm usr/share/applications/gtk-recordmydesktop.desktop

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


if [[ $ARCH = "" ]]; then
 echo "Set the default GTK theme to the cool one"
 #rm -r usr/share/themes/Raleigh
 ln -s /usr/share/themes/QtCurve/ usr/share/themes/Raleigh
elif [[ $ARCH = "64" ]]; then
 echo run your cleaning arch specific stuff here
fi

}


run-ldconfig() {
cd $SD && AUFS="aufs-temp"
echo "Running ldconfig and others chrooted inside $AUFS"

mkdir -p $AUFS
mount -t aufs -o br:03-Libs${ARCH} none $AUFS
mount -t aufs -o remount,append:02-Xorg${ARCH}-3D=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:01-Core${ARCH}=ro none $AUFS

chroot $AUFS ldconfig
chroot $AUFS rm -rf /etc/gtk-2.0/gtkrc
chroot $AUFS ln -sf /usr/share/themes/oxygen-gtk/gtk-2.0/gtkrc /etc/gtk-2.0/gtkrc
chroot $AUFS useradd -s /bin/false -d / -u 98 usbmux

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
	  clean-Lib
	  run-ldconfig
	 ;;
	 "lzmfy" )
	  echo "...LZMFY"
	  rm -f $NP.lzm
	  mksquashfs $NP $NP.lzm -b 256k
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
	  mksquashfs $NP $NP.lzm -b 256k
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi
