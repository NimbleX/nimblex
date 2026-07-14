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

provision_test_vsock() {
# Provision the test ISO's rootcopy + host so the freshly built VM is
# reachable over SSH-over-AF_VSOCK, without any guest network config.
# (64-bit only; systemd-ssh-generator + systemd-ssh-proxy, needs systemd >=256.)
[ "$ARCH" = "64" ] || return 0

RC=ISO-test${ARCH}/nimblex${ARCH}/rootcopy
PUBKEY=${VSOCK_PUBKEY:-$HOME/.ssh/id_ed25519.pub}

# Host side: vsock backend + ssh drop-in include (both are no-ops if present).
modprobe vhost_vsock 2>/dev/null || true
grep -q '^Include /etc/ssh/ssh_config.d/' /etc/ssh/ssh_config 2>/dev/null || \
	sed -i '1iInclude /etc/ssh/ssh_config.d/*.conf' /etc/ssh/ssh_config

# Guest side (baked into the read-only ISO's rootcopy overlay):
mkdir -p $RC/root/.ssh $RC/etc/systemd/system/multi-user.target.wants
if [ -f "$PUBKEY" ]; then
	install -m 700 -d $RC/root/.ssh
	install -m 600 "$PUBKEY" $RC/root/.ssh/authorized_keys
else
	echo "WARNING: $PUBKEY not found; vsock SSH into the test VM will fail."
fi
# Generate host keys at boot (in the RAM union, mode 0600). We must NOT ship
# keys on the ISO: cp -a off iso9660 lands them 0444 and sshd rejects them.
rm -f $RC/etc/ssh/ssh_host_*
ln -sf /usr/lib/systemd/system/sshdgenkeys.service \
	$RC/etc/systemd/system/multi-user.target.wants/sshdgenkeys.service

# Debug channel: autologin root on the serial console (the VM's <console>,
# i.e. /dev/pts/N via `virsh ttyconsole NX64`). Handy for diagnosing boots
# where even vsock SSH fails.
mkdir -p $RC/etc/systemd/system/serial-getty@ttyS0.service.d \
	 $RC/etc/systemd/system/getty.target.wants
cat > $RC/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear - 115200,38400,9600 vt220
EOF
ln -sf /usr/lib/systemd/system/serial-getty@.service \
	$RC/etc/systemd/system/getty.target.wants/serial-getty@ttyS0.service
}

create_iso() {
provision_test_vsock
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

grub-mkrescue -o ../NimbleX${ARCH}-test.iso ISO-test${ARCH} -- -volid "NIMBLEX"
}

run_vm() {

create_iso
virsh create NimbleX${ARCH}-test.xml

set +e

while ! virsh list | grep -w NX${ARCH}; do
	echo -n .
done

# Wait for the guest to become reachable over SSH-over-vsock before we
# open the graphical viewer, so scripted runs get a clear ready signal.
if [ -n "$VM_SSH" ]; then
	echo -n "Waiting for $VM_SSH ..."
	for i in $(seq 1 40); do
		if ssh -o ConnectTimeout=5 -o BatchMode=yes \
			-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
			$VM_SSH 'true' 2>/dev/null; then
			echo " up."; ssh $VM_SSH 'uname -a; uptime'; break
		fi
		echo -n .; sleep 5
	done
fi

spicy --uri=spice+unix:///tmp/nx64-spice.sock

set -e
}

build_package() {
	PKG=`basename $1`
	rsync -e 'ssh' -ahH --delete `dirname $1`/${PKG} $VM_SSH:
	ssh $VM_SSH "cd $PKG && ./*.SlackBuild"
	ssh $VM_SSH "installpkg /tmp/${PKG}*.txz"
	scp $VM_SSH:/tmp/${PKG}*.txz /tmp/
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
	# Reach the freshly built VM over SSH-over-AF_VSOCK (CID 3 in the test XML).
	VM_SSH="root@vsock/3"
elif [ $2 = "32" ]; then
	VM_IP="192.168.122.11"
	VM_SSH="$VM_IP"
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
#	./10-Virtual.sh world
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
