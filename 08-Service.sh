#!/bin/bash
set -e

START=`date +%s`

cp_new_lzm() {

# Uncomment to enable REMOTE
#REMOTE="admin@seif:/share/Bogdan/packages/nimblex/lzm/"

if [ ! -d ISO-test${ARCH} ]; then mkdir ISO-test${ARCH}; fi

rsync -av	01-Core${ARCH}.lzm \
		02-Xorg${ARCH}.lzm \
		04-Apps${ARCH}.lzm \
		05-KDE${ARCH}.lzm \
		07-Devel${ARCH}.lzm \
		10-Virtual${ARCH}.lzm \
ISO-test${ARCH}/nimblex${ARCH}/

if [ ! -z $REMOTE ]; then
	rsync -av	01-Core${ARCH}.lzm \
			02-Xorg${ARCH}.lzm \
			04-Apps${ARCH}.lzm \
			05-KDE${ARCH}.lzm \
			07-Devel${ARCH}.lzm \
			10-Virtual${ARCH}.lzm \
	$REMOTE
fi

}

create_iso() {
# First we have to make sure a VM is not booted of this
set +e
lsof ../NimbleX${ARCH}-test.iso | grep -q qemu
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

grub-mkrescue -o ../NimbleX${ARCH}-test.iso ISO-test${ARCH}
}

run_vm() {
virsh create NimbleX${ARCH}-test.xml

set +e

while ! virsh list | grep -w NX${ARCH}; do
	echo -n .
done

for i in {9..0}; do echo -en "\r$i"; sleep 3;done; echo -en "\r"
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
	world
	big-world
	small-world
	
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

case $1 in
  "reset" )
	virsh reset `virsh list | grep -w NX${ARCH} | awk '{print $1}'`
  ;;
  "run" )
	run_vm
  ;;
  "create_iso" )
	create_iso
  ;;
  "cp_new_lzm" )
	cp_new_lzm
  ;;
  "build" )
	build_package $3
  ;;
  "world" )
	./01-Core.sh clean
	./01-Core.sh world
	./02-Xorg.sh clean
	./02-Xorg.sh world
	./04-Apps.sh clean
	./04-Apps.sh world
	./05-KDE.sh clean
	./05-KDE.sh world
	./07-Devel.sh clean
	./07-Devel.sh world
	./10-Virtual.sh world
  ;;
  "big-world" )
	./01-Core.sh clean
	./01-Core.sh world
	./02-Xorg.sh clean
	./02-Xorg.sh world
	./04-Apps.sh clean
	./04-Apps.sh world
	./05-KDE.sh clean
	./05-KDE.sh world
	./07-Devel.sh clean
	./07-Devel.sh world
	./10-Virtual.sh world
	cp_new_lzm	# Something not OK here
	create_iso
	run_vm
  ;;
   "small-world" )
	cp_new_lzm
	create_iso
	run_vm
  ;;
 * )
	echo "Wazzup?"
  ;;

esac

echo "Finished in $((`date +%s` - $START))"
