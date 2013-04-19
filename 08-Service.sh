#!/bin/bash
set -e

cp_new_lzm() {
rsync -av	01-Core${ARCH}.lzm \
		02-Xorg${ARCH}-3D.lzm \
		02-Xorg${ARCH}.lzm \
		03-Libs${ARCH}.lzm \
		04-Apps${ARCH}.lzm \
		05-KDE${ARCH}.lzm \
		07-Devel${ARCH}.lzm \
ISO-test${ARCH}/nimblex${ARCH}/
}

create_iso() {
# First we have to make sure a VM is not booted of this
set +e
lsof ../../NimbleX${ARCH}-test.iso | grep -q qemu
if [ $? -eq "0" ]; then
	echo -e "A VM is started with this ISO.\nDo you want to shut it down? (y/n)"
	read -s -n 1 ANS
	case $ANS in
		"y" )
		  virsh destroy `virsh list | grep -w NX${ARCH} | awk '{print $1}'`
		;;
		"n" )
		  exit
		;;
	esac
fi
set -e

#rsync -Pha --checksum ../../NimbleX${ARCH}-test.iso /tmp/  # for some reason the checksum doesn't help
cp -av ../../NimbleX${ARCH}-test.iso /tmp/ 
grub-mkrescue -o ../../NimbleX${ARCH}-test.iso ISO-test${ARCH}
}

run_vm() {
virsh create ../NimbleX${ARCH}-test.xml

set +e

while ! virsh list | grep -w NX${ARCH}; do
	echo -n .
done

for i in {9..0}; do echo -en "\r$i"; sleep 1;done; echo -en "\r"
TRIES=10
a=1
while [ "$a" -le "$TRIES" ]; do
	ssh $VM_IP "uname -a; uptime"
	if [ $? = "0" ]; then
		a=10
	fi
	let "a+=1"
done

set -e
}

build_package() {
	PKG=`basename $1`
	rsync -e 'ssh' -ahH --delete `dirname $1`/${PKG} $VM_IP:
	ssh $VM_IP "cd $PKG && ./*.SlackBuild"
	ssh $VM_IP "installpkg /tmp/${PKG}*.txz"
	scp $VM_IP:/tmp/${PKG}*.txz /tmp/
}


if [[ $1 = "" || $2 = "" ]]; then
	echo -e "\n
	Usage: $0 COMMAND ARCH

	COMMANDS:
	reset
	run
	create_iso
	cp_new_lzm
	build
	
	ARCH:
	32
	64

	Example: $0 build 32 /mnt/sda1/Work/packages/libestr
	"
	exit
fi

if [ $2 = "64" ]; then
	ARCH=64
	VM_IP="192.168.122.10"
elif [ $2 = "32" ]; then
	VM_IP="192.168.122.11"
fi

if [ $1 = "" ]; then
	cp_new_lzm
elif [ $1 = "reset" ]; then
	virsh reset `virsh list | grep -w NX${ARCH} | awk '{print $1}'`
elif [ $1 = "run" ]; then
	run_vm
elif [ $1 = "create_iso" ]; then
	create_iso
elif [ $1 = "cp_new_lzm" ]; then
	cp_new_lzm
elif [ $1 = "build" ]; then
	build_package $3
else
	echo "Unknown command"
fi
