#!/bin/bash
set -e

. .ftp-credentials

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

extrasrc="http://repository.slacky.eu/slackware${ARCH}-13.1/"
extrasrc="http://packages.nimblex.net/slacky${ARCH}/"

blacklist_kde="kdeartwork-*,calligra-*,marble-*,kstars-*,kiten-*,kgeography-*,parley-*,kalzium-*,ktouch-*,kig-*,kwordquiz-*,kremotecontrol-*,kbruch-*,khangman-*,kmplot-*,kanagram-*,klettres-*,kdevelop-*,ktorrent-*,libktorrent-*,blinken-*,kalgebra-*,cantor-*,kdetoys*,skanlite*,kdeadmin*,networkmanagement-*,amarok-*,kdepim-*,kplayer-*,amor-*,artikulate-*"
blacklist_kde=$blacklist_kde",ktuberling-*,kdiamond-*,pairs-*,kpat-*,kmahjongg-*,libkmahjongg-*,kajongg-*,kgoldrunner-*,palapeli-*,kbounce-*,granatier-*,kbreakout-*,kigo-*,kwordquiz-*,ksirk-*,rocs-*,kturtle-*,step-*,nepomuk-*,kget-*,cervisia-*,kapptemplate-*,kcachegrind-*,kde-dev-*,kdev-python-*,kompare-*,ksystemlog-*,ktux-*,lokalize-*,okteta-*,umbrello-*"
whitelist_l="clucene*,soprano*,qimageblitz*,strigi*,phonon-*,redland*,qca*,liblastfm*,libxklavier*,poppler*,libtiff*,libspectre*,libwnck*,attica*,eggdbus*,ebook-tools*,libdiscid*,shared-desktop-ontologies*,libiodbc*,herqq-*,libbluedevil-*,xapian-core-*,NOTYET_akonadi*"
blacklist_kde=$blacklist_kde",kdevplatform-*,kdewebdev-*,kdesdk-*,kfloppy-*,kdf-*,kmouth-*"

mkdir -p $NP-work $NP $NP-removed/man_pages/usr/man $NP-removed/locale/usr/share/locale $NP-removed/devel/usr/{include,lib${ARCH}}

downloadpkg() {
cd $SD/$NP-work
wget -R "$blacklist_kde" "$slacksrc"/kde/*.txz
wget -A "$whitelist_l" "$slacksrc"/l/*.txz
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
rm -r usr/share/wallpapers/{Autumn,Blue_Wood,Grass,Hanami,Horos,Flying_Field,Azul,Ariya,Prato,Auros}
rm -r usr/share/apps/k3b/pics/73lab		# ~ 200K
rm -r usr/share/apps/k3b/pics/crystal		# ~ 300K
rm -r usr/share/apps/k3b/extra			# Photo2vcd crap ~ 600K
rm -r usr/share/apps/kopete/styles/Konqi	# ~ 820K
rm -r usr/share/gtk-doc/html		
rm -r usr/share/poppler/cMap/Adobe-Japan1	# ~620K
rm -r usr/share/poppler/cMap/Adobe-Korea1	# ~280K
rm -r usr/share/apps/ksplash/Themes/Default	# Instead we will use our own
rm -r usr/share/apps/kdm/themes/{circles,horos,oxygen,oxygen-air}

# Copy lzm related ServiceMenus
cp ../06-NimbleX/usr/share/kde4/services/ServiceMenus/dir2lzm.desktop usr/share/kde4/services/ServiceMenus/
cp ../06-NimbleX/usr/share/kde4/services/ServiceMenus/lzm2dir.desktop usr/share/kde4/services/ServiceMenus/
cp ../06-NimbleX/usr/share/kde4/services/ServiceMenus/lzm_activate.desktop usr/share/kde4/services/ServiceMenus/

# Copy NimbleX specific files
cp -a ../06-NimbleX/usr/share/apps/{konsole,ksplash,kdm} usr/share/apps/
cp -a ../06-NimbleX/usr/share/config/{kickoffrc,konquerorrc,kxkbrc,kwalletrc,kppprc,ksplashrc} usr/share/config/
cp -a ../06-NimbleX/usr/share/apps/konsole/ usr/share/apps/
cp ../06-NimbleX/etc/kde/kdm/kdmrc etc/kde/kdm/

# Clean the little things
rm usr/share/applications/kde4/{Help.desktop,dbpedia_references.desktop}
rm usr/share/applications/kde4/kwalletmanager.desktop
rm usr/share/apps/remoteview/zeroconf.desktop

# Don't autostart stuff that we don't care about
#rm usr/share/autostart/nepomukserver.desktop

# Clean things from various packages
rm -r usr/share/apps/carddecks/{svg-dondorf,svg-gm-paris,svg-oxygen-white,svg-jolly-royal,svg-oxygen}

echo "Moving other usless crap.(doc/include/man/locale)"
# Handle Man pages
mv usr/man/* ../$NP-removed/man_pages/usr/man/
# Handle locale
mv usr/share/locale/* ../$NP-removed/locale/usr/share/locale/
# Handle .h & .a files
mv usr/include/* ../$NP-removed/devel/usr/include/
}

run-ldconfig() {
echo "Running ldconfig chrooted inside $AUFS"

cd $SD && AUFS="aufs-temp" && mkdir -p $AUFS
mount -t aufs -o xino=/mnt/live/memory/aufs.xino,br:$NP none $AUFS
mount -t aufs -o remount,append:04-Apps${ARCH}=ro none $AUFS
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
	  clean-KDE
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
	  clean-KDE
	  run-ldconfig
	  echo "...LZMFY"
	  mksquashfs $NP $NP.lzm $SQUASH_OPT
	 ;;
	esac
	echo -e "\n $0 \033[7m DONE \033[0m \n"
fi
