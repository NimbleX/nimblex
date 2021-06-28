#!/bin/bash
set -e

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

extrasrc="https://packages.slackonly.com/pub/packages/"

# In April 2015 XINE grew by 8MB.
whitelist_xap="gimp*,mozilla-firefox*,imagemagick*,xine*,xmms*,rdesktop*,blueman*,MPlayer-*,pavucontrol-*,gparted-*"
whitelist_n="samba-*"
whitelist_l="talloc-*,tevent-*,gcr-*,mozjs68-*"

mkdir -p $NP $NP-work $NP-removed/man_pages/usr/man $NP-removed/locale/usr/share/locale $NP-removed/devel/usr/{include,lib${ARCH}}

downloadpkg() {
cd $NP-work
wget -N -A "$whitelist_xap" "$slacksrc"/xap/*.txz
wget -N -A "$whitelist_n" "$slacksrc"/n/*.txz
wget -N -A "$whitelist_l" "$slacksrc"/l/*.txz

if [[ $ARCH = "" ]]; then
 wget -N $extrasrc/system/gslapt/0.5.3i/gslapt-0.5.3i-i486-1sl.txz # 125K
elif [[ $ARCH = "64" ]]; then
 wget -N $extrasrc/current-x86_64/network/transmission/transmission-2.92-x86_64-3_slonly.txz # 1.5M
 wget -N http://packages.nimblex.net/nimblex/gslapt-0.5.4a-x86_64-1.tgz #167K
 wget -N http://www.slackware.com/~alien/slackbuilds/chromium/pkg64/current/chromium-91.0.4472.114-x86_64-1alien.txz #73M
fi

wget -N $slacksrc/l/system-config-printer-*.txz
}

instpkg() {
for pkg in $SD/$NP-work/*.t?z ; do
   installpkg --root $SD/$NP $pkg
done
}

clean-apps() {
cd $SD/$NP
rm -r usr/doc/*
rm -r usr/share/gtk-doc/*
rm -r usr/share/xine/visuals/*
#rm -r usr/share/abiword-2.8/strings

echo Moving .h, .a files, man pages and localizations
# Handle Man pages
mv usr/man/* ../$NP-removed/man_pages/usr/man/
# Handle locale
mv usr/share/locale/* ../$NP-removed/locale/usr/share/locale/
# Handle .h & .a files
mv usr/include/* ../$NP-removed/devel/usr/include/
#mv usr/lib${ARCH}/*.a ../$NP-removed/devel/usr/lib${ARCH}/ # So far there isn't any .a file here

mkdir -p root/.config/
cp -a ../06-NimbleX/root/.config/transmission root/.config/

cd $SD/$NP/usr/lib${ARCH}
ln -s firefox-*/lib*.so .
}

cripple_gimp() {
cd $SD/$NP
rm usr/share/gimp/2.0/brushes/Texture/Texture-Hose*.gih
rm usr/share/gimp/2.0/brushes/Media/Acrylic-{04,05}.gih
rm usr/share/gimp/2.0/brushes/Splatters/Splats-0*.gih
rm usr/share/gimp/2.0/brushes/gimp-obsolete-files/{Grass1,feltpen}.gih
rm usr/share/gimp/2.0/brushes/Legacy/vine.gih
}

cripple_samba() {
cd $SD/$NP
rm usr/sbin/winbindd
rm -r usr/share/samba/setup
rm usr/bin/{smbtorture,net,rpcclient}
rm -r usr/lib$ARCH/service
}

cripple_mplayer() {
cd $SD/$NP
rm usr/bin/mencoder # Sorry to let you go, but you're a fat bastartd :|
cp -a ../06-NimbleX/usr/share/mplayer/skins/proton usr/share/mplayer/skins/
(cd usr/share/mplayer/skins/ && rm default && ln -s proton default)
sed -i 's/#framedrop = yes/framedrop = yes/g' etc/mplayer/mplayer.conf
sed -i 's/#cache = 8192/cache = 4096/g' etc/mplayer/mplayer.conf
sed -i 's/#cache-min = 20.0/cache-min = 20.0/g' etc/mplayer/mplayer.conf
}

run-ldconfig() {
cd $SD && AUFS="aufs-temp" && mkdir -p $AUFS
echo "Running ldconfig and others chrooted inside $AUFS"
mount -t aufs -o xino=/mnt/live/memory/aufs.xino,br:$NP none $AUFS
#mount -t aufs -o remount,append:03-Libs${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg${ARCH}=ro none $AUFS
mount -t aufs -o remount,append:01-Core${ARCH}=ro none $AUFS

chroot $AUFS ldconfig
chroot $AUFS glib-compile-schemas /usr/share/glib-2.0/schemas/

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
	  clean-apps
          cripple_gimp
          cripple_samba
          cripple_mplayer
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
	  clean-apps
          cripple_gimp
          cripple_samba
          cripple_mplayer
	  run-ldconfig
	  echo "...LZMFY"
	  mksquashfs $NP $NP.lzm $SQUASH_OPT
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi
