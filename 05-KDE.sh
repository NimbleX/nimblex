#!/bin/bash
set -e

SD=`pwd`
ARCH=""
if [[ `uname -m` = "x86_64" ]]; then ARCH="64" ; fi
NP=`basename $0 | cut -d "." -f 1`${ARCH} # NimbleX Package name
slacksrc="ftp://ftp.rdsbv.ro/mirrors/slackware/slackware${ARCH}-current/slackware${ARCH}"
slacksrc="ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware${ARCH}-current/slackware${ARCH}"
extrasrc="http://repository.slacky.eu/slackware${ARCH}-13.1/"

blacklist_kde="koffice*,kdeedu*,kdegames*,kdeartwork*,kdevelop*,ktorrent*,kdetoys*,skanlite*,kdeadmin*"
whitelist_l="clucene*,soprano*,qimageblitz*,strigi*,phonon*,redland*,qca*,liblastfm*,libxklavier*,poppler*,libtiff*,libspectre*,libwnck*,attica*,eggdbus*,ebook-tools*,libdiscid*,shared-desktop-ontologies*,libiodbc*,NOTYET_akonadi*"
blacklist_kde=$blacklist_kde",kdevplatform*,kdewebdev*,kdeaccessibility*" # Saves just 2MB

mkdir -p $NP-work $NP $NP-removed/man_pages/usr/{man,share/doc/HTML} $NP-removed/locale/usr/share/locale $NP-removed/devel/usr/{include,lib${ARCH}}

downloadpkg() {
cd $SD/$NP-work
wget -R "$blacklist_kde" "$slacksrc"/kde/*.txz
wget -A "$whitelist_l" "$slacksrc"/l/*.txz

# wget http://repository.slacky.eu/slackware-13.0/libraries/fam/2.7.0/fam-2.7.0-i486-4sl.txz
}

instpkg() {
for pkg in $SD/$NP-work/* ; do
   installpkg --root $SD/$NP $pkg
done
}

clean-KDE() {
cd $SD/$NP
echo "Removing SOME of the most usless crap (doc/wallpapers/k3b-themes)"
rm -r usr/doc
rm -r usr/share/wallpapers/{Aghi,Autumn,Blue_Wood,Ethais,Evening,Fields_of_Peace,Grass,Hanami,Quadros,Red_Leaf}
#rm -r usr/share/wallpapers/The_Rings_of_Saturn
#rm -r usr/share/wallpapers/Curls_on_Green
#rm -r usr/share/wallpapers/Spring_Sunray
#rm -r usr/share/wallpapers/Code_Poets_Dream
rm -r usr/share/apps/k3b/pics/73lab		# ~ 200K
rm -r usr/share/apps/k3b/pics/crystal		# ~ 300K
rm -r usr/share/apps/k3b/extra		# Photo2vcd crap ~ 600K
rm -r usr/share/apps/kopete/styles/Konqi	# ~ 820K
rm -r usr/share/gtk-doc/html		
rm -r usr/share/poppler/cMap/Adobe-Japan1	# ~620K
rm -r usr/share/poppler/cMap/Adobe-Korea1	# ~280K
# Linking background.png in the default ksplash theme will save us ~ 3MB
# usr/share/apps/ksplash/Themes/Default
# rm usr/share/apps/ksplash/Themes/Default/1920x1200/background.png usr/share/apps/ksplash/Themes/Default/1600x1200/background.png usr/share/apps/ksplash/Themes/Default/1280x1024/background.png usr/share/apps/ksplash/Themes/Default/1024x768/background.png
# rm -r usr/share/apps/ksplash/Themes/Default/600x400 usr/share/apps/ksplash/Themes/Default/800x600
# ln -s /usr/share/wallpapers/Air/contents/images/1920x1200.jpg usr/share/apps/ksplash/Themes/Default/1920x1200/background.png 
# ln -s /usr/share/wallpapers/Air/contents/images/1600x1200.jpg usr/share/apps/ksplash/Themes/Default/1600x1200/background.png
# ln -s /usr/share/wallpapers/Air/contents/images/1280x1024.jpg usr/share/apps/ksplash/Themes/Default/1280x1024/background.png 
# ln -s /usr/share/wallpapers/Air/contents/images/1024x768.jpg usr/share/apps/ksplash/Themes/Default/1024x768/background.png

# Copy lzm related ServiceMenus
cp ../06-NimbleX/usr/share/kde4/services/ServiceMenus/dir2lzm.desktop usr/share/kde4/services/ServiceMenus/
cp ../06-NimbleX/usr/share/kde4/services/ServiceMenus/lzm2dir.desktop usr/share/kde4/services/ServiceMenus/
cp ../06-NimbleX/usr/share/kde4/services/ServiceMenus/lzm_activate.desktop usr/share/kde4/services/ServiceMenus/

# Copy NimbleX specific files
cp ../06-NimbleX/usr/share/apps/{kdm,ksplash} usr/share/apps/

# Clean the little things
rm usr/share/applications/kde4/{Help.desktop,dbpedia_references.desktop,kbugbuster.desktop,KFloppy.desktop}
# rm usr/share/applications/kde4/kpilot*
rm usr/share/applications/kde4/akonadi*
rm usr/share/applications/kde4/kwalletmanager.desktop
rm usr/share/apps/remoteview/zeroconf.desktop

# Don't autostart stuff that we don't care about
rm usr/share/autostart/{kaddressbookmigrator.desktop,nepomukserver.desktop,printer-applet.desktop,kalarm.autostart.desktop,korgac.desktop}
#rm usr/share/autostart/irkick.desktop

echo "Moving other usless crap.(doc/include/man/locale)"
# Handle Man pages
mv usr/man/* ../$NP-removed/man_pages/usr/man/
mv usr/share/doc/HTML/* ../$NP-removed/man_pages/usr/share/doc/HTML/
# Handle locale
mv usr/share/locale/* ../$NP-removed/locale/usr/share/locale/
# Handle .h & .a files
mv usr/include/* ../$NP-removed/devel/usr/include/
}

run-ldconfig() {
echo "Running ldconfig and others chrooted inside $AUFS"

cd $SD && AUFS="aufs-temp" && mkdir -p $AUFS
mount -t aufs -o br:$NP none $AUFS
mount -t aufs -o remount,append:04-Apps=ro none $AUFS
mount -t aufs -o remount,append:03-Libs=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg-3D=ro none $AUFS
mount -t aufs -o remount,append:02-Xorg=ro none $AUFS
mount -t aufs -o remount,append:01-Core=ro none $AUFS

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
	  clean-KDE
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
	  clean-KDE
	  run-ldconfig
	  echo "...LZMFY"
	  mksquashfs $NP $NP.lzm -noappend -b 256k
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi
