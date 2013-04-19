#!/bin/bash
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`${ARCH} # NimbleX Package name
slacksrc="ftp://ftp.rdsbv.ro/mirrors/slackware/slackware${ARCH}-current/slackware${ARCH}"
slacksrc="ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware${ARCH}-current/slackware${ARCH}"
slacksrc="ftp://admin:crdq2f6qwv@seif/Bogdan/packages/slackware${ARCH}/slackware${ARCH}"
extrasrc="http://repository.slacky.eu/slackware${ARCH}-13.37/"
extrasrc="http://packages.nimblex.net/slacky${ARCH}/"

whitelist_xap="gimp*,mozilla-firefox*,imagemagick*,xine*,xmms*,rdesktop*,blueman*,MPlayer-*"
whitelist_n="samba-*"

mkdir -p $NP $NP-work $NP-removed/man_pages/usr/man $NP-removed/locale/usr/share/locale $NP-removed/devel/usr/{include,lib${ARCH}}

downloadpkg() {
cd $NP-work
wget -N -A "$whitelist_xap" "$slacksrc"/xap/*.txz
wget -N -A "$whitelist_n" "$slacksrc"/n/*.txz

if [[ $ARCH = "" ]]; then
 wget -N $extrasrc/system/gparted/0.14.0/gparted-0.14.0-i486-1sl.txz # 1.4M
 wget -N $extrasrc/network/transmission/2.77/transmission-2.77-i486-1sl.txz # 1.1M
 wget -N $extrasrc/utilities/yakuake/2.9.9/yakuake-2.9.9-i486-1sl.txz # 350K
# wget -N $extrasrc/multimedia/Transcoder/0.0.6/Transcoder-0.0.6-i686-1sl.txz # 30K
 wget -N $extrasrc/system/gslapt/0.5.3h/gslapt-0.5.3h-i486-1sl.txz # 124K
# wget -N $extrasrc/multimedia/mpd/0.15.16/mpd-0.15.16-i486-1sl.txz # 170K
 wget -N $extrasrc/office/abiword/2.8.6/abiword-2.8.6-i486-9sl.txz # 3.5M
elif [[ $ARCH = "64" ]]; then
 wget -N $extrasrc/system/gparted/0.14.1/gparted-0.14.1-x86_64-2sl.txz # 1.4M
# wget -N $extrasrc/network/qtransmission/2.75/qtransmission-2.75-x86_64-1sl.txz # 1.1M
 wget -N $extrasrc/network/transmission/2.75/transmission-2.75-x86_64-1sl.txz # 1.0M
 wget -N $extrasrc/utilities/yakuake/2.9.9/yakuake-2.9.9-x86_64-1sl.txz # 350K
# wget -N $extrasrc/system/gslapt/0.5.3f/gslapt-0.5.3f-x86_64-1sl.txz # 121K
 wget -N $extrasrc/office/abiword/2.8.6/abiword-2.8.6-x86_64-2sl.txz # 3.5M
fi

wget -N $slacksrc/l/system-config-printer-*.txz
}

instpkg() {
for pkg in $SD/$NP-work/*.txz ; do
   installpkg --root $SD/$NP $pkg
done
}

clean-apps() {
cd $SD/$NP
rm -r usr/doc/*
rm -r usr/share/gtk-doc/*
rm -r usr/share/xine/visuals/*
rm -r usr/share/abiword-2.8/strings

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
echo "Please test if FF libs are linked"
}

cripple_gimp() {
cd $SD/$NP
rm usr/share/gimp/2.0/brushes/Texture/Texture-Hose*.gih
rm usr/share/gimp/2.0/brushes/Media/Acrylic-{04,05}.gih
rm usr/share/gimp/2.0/brushes/Splatters/Splats-0*.gih
rm usr/share/gimp/2.0/brushes/gimp-obsolete-files/{Grass1,feltpen}.gih
rm usr/share/gimp/2.0/brushes/Legacy/vine.gih
rm usr/share/gimp/2.0/patterns/{stone33,cracked,crinklepaper,pink_marble,starfield,walnut,nops,bluesquares,ice}.pat
}

cripple_samba() {
cd $SD/$NP
rm usr/sbin/{winbindd,swat}
rm usr/bin/{net,rpcclient,smbget,smbcacls,smbclient,smbcquotas,smbtree,smbspool,ntlm_auth,pdbedit,eventlogadm,smbcontrol,smbstatus,nmblookup,wbinfo,testparm,sharesec,profiles,smbta-util}
rm -r usr/share/swat
rm usr/lib$ARCH/libnetapi.*
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
mount -t aufs -o remount,append:03-Libs${ARCH}=ro none $AUFS
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
