#!/bin/bash

VER=5.14.0
ARCH=i486
TXZD="/mnt/sda6/oss/slackware32/slackware-current/d/"

rm -rf perl-${VER} perl-removed
mkdir -p perl-removed/usr/share/perl5/ perl-removed/usr/lib/perl5/auto/Encode perl-removed/usr/lib/perl5/CORE

mkdir -p $TXZD
wget -P $TXZD ftp://ftp.iasi.roedu.net/mirrors/ftp.slackware.com/pub/slackware/slackware-current/slackware/d/perl-5.14.0-i486-1.txz
installpkg -root perl-${VER} $TXZD/perl-${VER}*.txz

mv perl-${VER}/usr/{man,doc} perl-removed/usr/
mv perl-${VER}/usr/share/perl5/pod perl-removed/usr/share/perl5/
mv perl-${VER}/usr/lib/perl5/auto/Encode/{JP,KR,CN,TW} perl-removed/usr/lib/perl5/auto/Encode/ 
mv perl-${VER}/usr/lib/perl5/CORE/*.h perl-removed/usr/lib/perl5/CORE/
# mv perl-${VER}/usr/lib/perl5/${VER}/pod perl-removed/usr/lib/perl5/${VER}/

dir2lzm perl-${VER} perl-${VER}.lzm

