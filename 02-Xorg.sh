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

blacklist_x="sazanami*,font-adobe*,wqy-zenhei-font*,xorg-docs*,anthy*,font-bh*,font-misc*,ttf-indic*,tibmachuni-font*,font-isas*,font-daewoo*,font-jis*,font-cronyx*,font-mutt*,font-schumacher*,sinhala_lklug*"
blacklist_x=$blacklist_x",scim*,m17n*,libhangul*,xorg-server-xephyr*,xorg-server-xnest*,xedit*"

whitelist_d="llvm-*" # We need this for using standard mesa. If we want to save a lot of space we should compile mesa without llvm and should exclude llvm from here.

whitelist_l="libxkbcommon-*,libxdg-basedir-*,hicolor-icon-theme*,icon-naming-utils*,hal*,exiv2*,gst*,libical*,libungif*,chmlib*,shared-mime-info-*,gtk+*,libgtkhtml*,pygtk*,atk*,at-spi2-*,jasper*,harfbuzz-*,pango*,cairo*,pycairo*,enchant*,gtkspell*,sip*,libglade*,PyQt-*,libxslt*,libnotify*,startup-notification*,libdvdread*,libvncserver*,libgpod*,libmtp*,libjpeg*,libpng*,giflib*,babl*,gegl*,lcms*,pycups*,notify-python*,lesstif*,t1lib*,ilmbase*,librsvg*,imlib*,libgsf*,libexif*,libmng*,libwmf*,openexr*,sdl*,djvulibre*,libwpd*,libart_lgpl*,fribidi*,vte*,gamin*,freetype*,fribidi*,libdbusmenu-*,gdk-pixbuf2*,desktop-file-utils-*,libcroco-*,libsoup-*,GConf-*,libgnome-keyring-*,libcanberra-*,qjson-*,libdvdnav-*,openjpeg-*,libva-*,LibRaw-*,gtkmm2-*,gtkmm3-*,libbluray-*,ocl-icd-*,gsettings-desktop-schemas-*,libwebp-*,libunwind-*,json-glib-*,gexiv2-*,graphite2-*,brotli-*,libsecret-*,libindicator-*,libappindicator-*,openal-soft-*,qt5-*"

whitelist_xap="rxvt-unicode-*,libnma-*,network-manager-applet-*"

whitelist_kde="oxygen-gtk2-*,oxygen-gtk3-*"

mkdir -p $NP $NP-work $NP-removed/man_pages/usr/man $NP-removed/locale/usr/share/{locale,qt5} $NP-removed/devel/usr/{include,lib64}

downloadpkg() {
cd $SD/$NP-work
wget -N -R "$blacklist_x" "$slacksrc"/x/*.txz
wget -N -A "$whitelist_d" "$slacksrc"/d/*.txz
wget -N -A "$whitelist_l" "$slacksrc"/l/*.txz
wget -N -A "$whitelist_xap" "$slacksrc"/xap/*.txz
wget -N -A "$whitelist_kde" "$slacksrc"/kde/*.txz

if [[ $ARCH = "" ]]; then
 wget -N http://packages.nimblex.net/nimblex/i3-4.2-i486-2.txz		# 641K
 wget -N http://packages.nimblex.net/nimblex/i3status-2.8-i686-1.txz	# 38K
 wget -N http://packages.nimblex.net/nimblex/dmenu-4.5-i686-1.txz	# 15K
elif [[ $ARCH = "64" ]]; then
 wget -N http://packages.nimblex.net/nimblex/i3-4.23-x86_64-1.txz	# 1.1M
 wget -N http://packages.nimblex.net/nimblex/i3status-2.14-x86_64-1.txz	# 49K
 wget -N http://packages.nimblex.net/nimblex/xcb-util-xrm-1.3-x86_64-1.txz	# 32K
 wget -N http://packages.nimblex.net/nimblex/dmenu-4.8-x86_64-1.txz	# 20K
 wget -N http://packages.nimblex.net/nimblex/imlib2-1.7.1-x86_64-1.txz	# 536K
 wget -N http://packages.nimblex.net/nimblex/feh-3.6.1-x86_64-1.txz	# 166K
 wget -N http://packages.nimblex.net/nimblex/dunst-1.5.0-x86_64-2.txz	# 70K
 wget -N http://packages.nimblex.net/nimblex/xsel-1.2.1-x86_64-1.txz	# 24K
fi

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
# Handle .h & .a files
mv usr/include/* ../$NP-removed/devel/usr/include/
mv usr/lib${ARCH}/*.a ../$NP-removed/devel/usr/lib${ARCH}/

# Handle usr/share/icons # 300KB
# Handle fonts (usr/share/fonts or txz packagez) (Maybe 2MB of data)
# Handle usr/share/X11/locale # 144KB

echo Cleaning QT/GTK stuff
rm -r usr/share/{gtk-doc/html,gtk-2.0/demo}
rm -r usr/lib${ARCH}/pygtk/2.0/demos
# We only handle these only if we are using the standard Qt package. There are many others which can be removed with QT5
#mv usr/lib${ARCH}/qt/lib/libQt{WebKit,Designer,3Support}.* ../$NP-removed/devel/usr/lib${ARCH}/qt/lib/
rm -r usr/share/qt5/{translations,phrasebooks} # 1.4MB
#mv usr/lib${ARCH}/qt5/bin/{qmake,qgltf,uic,uic,l*,qdoc,rcc,moc,qhelpconverter} ../$NP-removed/devel/usr/lib${ARCH}/qt5/bin/
rm -r usr/share/libwmf
}

nimblex_adjust() {
cd $SD/$NP

echo "Copying NimbleX specific shared files"
cp -a ../06-NimbleX/usr/share/icons/oxygen usr/share/icons/
cp ../06-NimbleX/usr/share/mime/packages/nimblex.xml usr/share/mime/packages/
mkdir -p usr/share/mime/application/ root/.config/
cp ../06-NimbleX/usr/share/mime/application/x-lzm.xml usr/share/mime/application/

cp -a ../06-NimbleX/usr/share/wallpapers usr/share/
cp -a ../06-NimbleX/usr/share/X11/xorg.conf.d usr/share/X11/
cp -a ../06-NimbleX/root/.config/dunst root/.config/
}

run-ldconfig() {
cd $SD && AUFS="aufs-temp"
echo "Running ldconfig and others chrooted inside $AUFS"

mount | grep aufs-temp && umount aufs-temp
mkdir -p $AUFS
mount -t aufs -o xino=/mnt/live/memory/aufs.xino,br:$NP none $AUFS
mount -t aufs -o remount,append:01-Core${ARCH}=ro none $AUFS

chroot $AUFS ln -s /lib/libudev.so.1.3.1 /lib/libudev.so.0	# Remove this after systemd update to 20.1
chroot $AUFS ldconfig
chroot $AUFS fc-cache
chroot $AUFS update-mime-database /usr/share/mime
chroot $AUFS update-gtk-immodules
chroot $AUFS update-gdk-pixbuf-loaders
chroot $AUFS glib-compile-schemas /usr/share/glib-2.0/schemas/
chroot $AUFS rm -rf /etc/gtk-2.0/gtkrc
chroot $AUFS ln -sf /usr/share/themes/oxygen-gtk/gtk-2.0/gtkrc /etc/gtk-2.0/gtkrc

umount $AUFS
rm -rf $NP/.wh..wh.*
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
	  clean-X
	  nimblex_adjust
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
	  clean-X
	  nimblex_adjust
	  run-ldconfig
	  echo "...LZMFY"
	  mksquashfs $NP $NP.lzm $SQUASH_OPT
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi
