#!/bin/bash
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`${ARCH} # NimbleX Package name
slacksrc="ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware${ARCH}-current/slackware${ARCH}"
slacksrc="ftp://admin:crdq2f6qwv@seif/Bogdan/packages/slackware${ARCH}/slackware${ARCH}"

blacklist_x="sazanami*,font-adobe*,wqy-zenhei-font*,xorg-docs*,anthy*,font-bh*,font-misc*,ttf-indic*,tibmachuni-font*,font-isas*,font-daewoo*,font-jis*,font-cronyx*,font-mutt*,font-bitstream*,font-schumacher*,sinhala_lklug*"
blacklist_x=$blacklist_x",scim*,m17n*,libhangul*,xorg-server-xephyr*,xorg-server-xnest*,xedit*"

whitelist_l="hicolor-icon-theme*,icon-naming-utils*,hal*,exiv2*,gst*,libical*,libungif*,libxml2*,chmlib*,shared-mime-info*,qt*,gtk*,libgtkhtml*,pygtk*,atk*,jasper*,pango*,cairo*,pycairo*,enchant*,gtkspell*,sip*,libglade*,PyQt*,libxslt*,libnotify*,startup-notification*,libdvdread*,libvncserver*,libgpod*,libplist*,libmtp*,libjpeg*,libpng*,giflib*,babl*,gegl*,lcms*,pycups*,notify-python*,lesstif*,t1lib*,ilmbase*,librsvg*,imlib*,libgsf*,libexif*,libmng*,libwmf*,openexr*,sdl*,djvulibre*,libwpd*,libart_lgpl*,fribidi*,vte*,gamin*,polkit*,freetype*,fribidi*,libdbusmenu-qt*,gdk-pixbuf2*"

mkdir -p $NP $NP-work $NP-removed/man_pages/usr/man $NP-removed/locale/usr/{share/locale,lib${ARCH}/qt} $NP-removed/devel/usr/{include,lib${ARCH}/qt/include}

downloadpkg() {
cd $SD/$NP-work
wget -N -R "$blacklist_x" "$slacksrc"/x/*.txz
wget -N -A "$whitelist_l" "$slacksrc"/l/*.txz

wget -N ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware${ARCH}-current/extra/google-chrome/GConf-*.txz
wget -N ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware${ARCH}-current/extra/google-chrome/ORBit2-*.txz
}

instpkg() {
for pkg in $SD/$NP-work/* ; do
   installpkg --root $SD/$NP $pkg
done
}

clean-X() {
cd $SD/$NP
rm -r usr/doc/*

echo Moving .h, .a files, man pages and localizations

# Handle Man pages
mv usr/man/* ../$NP-removed/man_pages/usr/man/
# Handle locale
mv usr/share/locale/* ../$NP-removed/locale/usr/share/locale/ # 250KB compiz and xkeyboard locale
mv usr/lib${ARCH}/qt/translations ../$NP-removed/locale/usr/lib${ARCH}/qt/ # 1.4MB
# Handle .h & .a files
mv usr/include/* ../$NP-removed/devel/usr/include/
mv usr/lib${ARCH}/*.a ../$NP-removed/devel/usr/lib${ARCH}/

echo Handle mesa as a separate package

mkdir -p $SD/$NP-3D/usr/lib${ARCH}/xorg/modules/
mv usr/lib${ARCH}/xorg/modules/dri $SD/$NP-3D/usr/lib${ARCH}/xorg/modules/

# Handle usr/share/icons # 300KB
# Handle fonts (usr/share/fonts or txz packagez) (Maybe 2MB of data)
# Handle usr/share/X11/locale # 144KB

echo Cleaning QT/GTK stuff
rm -r usr/share/{gtk-doc/html,gtk-2.0/demo}
rm -r usr/lib${ARCH}/pygtk/2.0/demos
rm -r usr/lib${ARCH}/qt/doc
rm -r usr/lib${ARCH}/qt/tests
mv usr/lib${ARCH}/qt/include/* ../$NP-removed/devel/usr/lib${ARCH}/qt/include/
rm -r usr/share/libwmf
}

nimblex_adjust() {
cd $SD/$NP
#echo "Copying some cache files - check to see if these are still OK"
#cp -a ../02-shared/etc/gtk-2.0 etc/
#cp -a ../02-shared/etc/pango etc/
#cp -a ../02-shared/usr/share/icons usr/share/
#cp -a ../02-shared/usr/share/mime usr/share/
#cp -a ../02-shared/usr/share/fonts usr/share/

echo "Copying NimbleX specific shared files"
cp -a ../06-NimbleX/usr/share/icons/oxygen usr/share/icons/
cp -a ../06-NimbleX/usr/share/hal/fdi/policy/10osvendor/* usr/share/hal/fdi/policy/10osvendor/
cp ../06-NimbleX/usr/share/mime/packages/nimblex.xml usr/share/mime/packages/
mkdir -p usr/share/mime/application/
cp ../06-NimbleX/usr/share/mime/application/x-lzm.xml usr/share/mime/application/

cp -a ../06-NimbleX/usr/share/wallpapers usr/share/
}

run-ldconfig() {
cd $SD && AUFS="aufs-temp"
echo "Running ldconfig and others chrooted inside $AUFS"

mkdir -p $AUFS
mount -t aufs -o xino=/mnt/live/memory/aufs.xino,br:$NP none $AUFS
mount -t aufs -o remount,append:$NP-3D=ro none $AUFS
mount -t aufs -o remount,append:01-Core${ARCH}=ro none $AUFS

chroot $AUFS ldconfig
chroot $AUFS fc-cache
chroot $AUFS update-mime-database /usr/share/mime
chroot $AUFS update-gtk-immodules
chroot $AUFS update-gdk-pixbuf-loaders
chroot $AUFS update-pango-querymodules
chroot $AUFS /usr/bin/gtk-update-icon-cache -t -f /usr/share/icons/hicolor/
# chroot $AUFS /usr/bin/gtk-update-icon-cache -t -f /usr/share/icons/oxygen/  # This is a KDE package and the cache will be HUGE!

umount $AUFS
rm -rf $NP/.wh..wh.*
}

if [[ -z $1 ]]; then
	echo "Tell me what to do"
	echo "You options are: clean download install lzmfy"
else
	case $1 in
	 "clean" )
	  echo "...CLEANING"
	  rm -r $NP && echo $NP deleted
	  rm -r $NP-3D && echo $NP-3D deleted
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
	  clean-X
	  nimblex_adjust
	  run-ldconfig
	 ;;
	 "lzmfy" )
	  echo "...LZMFY"
	  mksquashfs $NP $NP.lzm -noappend -b 256k -no-xattrs
	  mksquashfs $NP-3D $NP-3D.lzm -noappend -b 256k -no-xattrs
	 ;;
	 "world" )
	  echo "...DOWNLOADING"
	  downloadpkg
	  echo "...INSTALLING"
	  instpkg
	  clean-X
	  nimblex_adjust
	  run-ldconfig
	  echo "...LZMFY"
	  mksquashfs $NP $NP.lzm -noappend -b 256k -no-xattrs
	  mksquashfs $NP-3D $NP-3D.lzm -noappend -b 256k -no-xattrs
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi
