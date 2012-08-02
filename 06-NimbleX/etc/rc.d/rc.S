#!/bin/bash
#
# /etc/rc.d/rc.S:  System initialization script.
#
# Mostly written by:  Patrick J. Volkerding, <volkerdi@slackware.com>
# Modified by Bogdan Radulescu for NimbleX <bogdan@nimblex.net>

PATH=/sbin:/usr/sbin:/bin:/usr/bin

# Try to mount /proc:
/sbin/mount proc /proc -n -t proc 2> /dev/null

# Mount sysfs next, if the kernel supports it:
if [ -d /sys ]; then
  if grep -wq sysfs /proc/filesystems ; then
    if ! grep -wq sysfs /proc/mounts ; then
      /sbin/mount sysfs /sys -n -t sysfs
    fi
  fi
fi

# We need to see WTF takes soo long
# /sbin/bootchartd start
# /sbin/ureadahead --daemon -q &

if grep -wq sysfs /proc/mounts && grep -q tmpfs /proc/filesystems ; then
  if ! grep -wq nohotplug /proc/cmdline ; then
    if [ -x /etc/rc.d/rc.udev ]; then
      /bin/sh /etc/rc.d/rc.udev start
    fi
  fi
fi

# Initialize the Logical Volume Manager.
# This won't start unless we find /etc/lvmtab (LVM1) or
# /etc/lvm/backup/ (LVM2).  This is created by /sbin/vgscan, so to
# use LVM you must run /sbin/vgscan yourself the first time (and
# create some VGs and LVs).
if [ -r /etc/lvmtab -o -d /etc/lvm/backup ]; then
  echo "Initializing LVM (Logical Volume Manager):"
  # Check for device-mapper support.
  if ! grep -wq device-mapper /proc/devices ; then
    # Try to load a device-mapper kernel module:
    /sbin/modprobe -q dm-mod
  fi
  # Scan for new volume groups:
  /sbin/vgscan --mknodes --ignorelockingfailure 2> /dev/null
  if [ $? = 0 ]; then
    # Make volume groups available to the kernel.
    # This should also make logical volumes available.
    /sbin/vgchange -ay --ignorelockingfailure
  fi
fi

# Open any volumes created by cryptsetup:
if [ -f /etc/crypttab -a -x /sbin/cryptsetup.static ]; then
  # First, check for device-mapper support.
  if ! grep -wq device-mapper /proc/devices ; then
    # If device-mapper exists as a module, try to load it.
    # Try to load a device-mapper kernel module:
    /sbin/modprobe -q dm-mod
  fi
  # NOTE: we only support LUKS formatted volumes (except for swap)!
  cat /etc/crypttab | grep -v "^#" | grep -v "^$" | while read line; do
    eval LUKSARRAY=( $line )
    LUKS="${LUKSARRAY[0]}"
    DEV="${LUKSARRAY[1]}"
    PASS="${LUKSARRAY[2]}"
    OPTS="${LUKSARRAY[3]}"
    LUKSOPTS=""
    if echo $OPTS | grep -wq ro ; then LUKSOPTS="${LUKSOPTS} --readonly" ; fi

    # Skip LUKS volumes that were already unlocked (in the initrd):
    /sbin/cryptsetup.static status $LUKS 1>/dev/null 2>/dev/null && continue
    if /sbin/cryptsetup.static isLuks $DEV 2>/dev/null ; then
      echo "Unlocking LUKS crypt volume '${LUKS}' on device '$DEV':"
      if [ -n "${PASS}" ]; then
        if [ -f ${PASS} ]; then
          /sbin/cryptsetup.static ${LUKSOPTS} --key-file=${PASS} luksOpen $DEV $LUKS
        elif [ "${PASS}" != "none" ]; then
          # A password field of 'none' indicates a line for swap:
          echo "${PASS}" | /sbin/cryptsetup.static ${LUKSOPTS} luksOpen $DEV $LUKS
        fi
      else
        for i in seq 1 3 ; do
          /sbin/cryptsetup.static ${LUKSOPTS} luksOpen $DEV $LUKS </dev/tty0 >/dev/tty0 2>&1
          [ $? -eq 0 ] && break
        done
      fi
    elif echo $OPTS | grep -wq swap ; then
      # If any of the volumes is to be used as encrypted swap,
      # then encrypt it using a random key and run mkswap:
      echo "Creating encrypted swap on device '$DEV' mapped to '${LUKS}':"
      /sbin/cryptsetup.static --cipher=aes --key-file=/dev/urandom --key-size=256 create $LUKS $DEV
      mkswap /dev/mapper/$LUKS
    fi
  done
fi

# Start FUSE, if requested:
if [ -x /etc/rc.d/rc.fuse ]; then
  sh /etc/rc.d/rc.fuse start
fi

# Set the system time from the hardware clock using hwclock --hctosys.
if [ -x /sbin/hwclock ]; then
  # Check for a broken motherboard RTC clock (where ioports for rtc are
  # unknown) to prevent hwclock causing a hang:
  if ! grep -q -w rtc /proc/ioports ; then
    CLOCK_OPT="--directisa"
  fi
  if grep -wq "^UTC" /etc/hardwareclock 2> /dev/null; then
    echo "Setting system time from the hardware clock (UTC)."
    /sbin/hwclock $CLOCK_OPT --utc --hctosys &
  else
    echo "Setting system time from the hardware clock (localtime)."
    /sbin/hwclock $CLOCK_OPT --localtime --hctosys &
  fi
fi

# Remount the root filesystem in read-write mode
echo "Remounting root device with read-write enabled."
/sbin/mount -w -v -n -o remount /

# Any /etc/mtab that exists here is old, so we delete it to start over:
/bin/rm -f /etc/mtab*
# Remounting the / partition will initialize the new /etc/mtab:
/sbin/mount -w -o remount /

# Read in the correct / filesystem complete with arguments so mount will
# show them correctly. This does not stop those arguments from functioning
# but does prevent a small bug with /etc/mtab.
/bin/grep ' / ' /proc/mounts | grep -v "^rootfs" > /etc/mtab

/sbin/mount -f proc /proc -t proc
/sbin/mount -f sysfs /sys -t sysfs

# Configure ISA Plug-and-Play devices:
if [ -r /etc/isapnp.conf ]; then
  if [ -x /sbin/isapnp ]; then
    /sbin/isapnp /etc/isapnp.conf
  fi
fi

if [ -x /etc/rc.d/rc.modules -a -r /proc/modules ]; then
  echo "Running /etc/rc.d/rc.modules:"
  . /etc/rc.d/rc.modules
fi

# Configure runtime kernel parameters:
if [ -x /sbin/sysctl -a -r /etc/sysctl.conf ]; then
  /sbin/sysctl -e -p /etc/sysctl.conf
fi

# Check jfs because it might not allow us to mount it
# This will not really work at this point
# /sbin/fsck -R -A -a -t jfs

# Mount usbfs:
/sbin/mount -v usbfs /proc/bus/usb -t usbfs

# Mount non-root file systems in fstab, but not NFS or SMB 
# because TCP/IP is not yet configured, and not proc or sysfs
# because those have already been mounted.  Also check that
# devpts is not already mounted before attempting to mount
# it.  With a 2.6.x or newer kernel udev mounts devpts.
# We also need to wait a little bit to let USB and other
# hotplugged devices settle (sorry to slow down the boot):
echo "Mounting non-root local filesystems"
# sleep 3
/sbin/mount -a -t nonfs,nosmbfs,nocifs,noproc,nosysfs,nodevpts -o rw &

# Enable swapping.  This is needed in case a swapfile is used,
# as it can't be enabled until the filesystem it resides on has been
# mounted read-write.
# /sbin/swapon -a 2> /dev/null # if we fork the previous command in the background this one doesn't make sense

# Clean up some temporary files:
rm -f /var/run/* /var/run/*/* /var/run/*/*/* /etc/nologin \
  /etc/dhcpc/*.pid /etc/forcefsck /etc/fastboot \
  /var/state/saslauthd/saslauthd.pid \
  /tmp/.Xauth* 1> /dev/null 2> /dev/null
  ( cd /var/log/setup/tmp && rm -rf * )
  ( cd /tmp && rm -rf kde-[a-zA-Z]* ksocket-[a-zA-Z]* hsperfdata_[a-zA-Z]* plugtmp* )

# Create a fresh utmp file:
touch /var/run/utmp
chown root:utmp /var/run/utmp
chmod 664 /var/run/utmp

# If there are SystemV init scripts for this runlevel, run them.
if [ -x /etc/rc.d/rc.sysvinit ]; then
  . /etc/rc.d/rc.sysvinit
fi

# Run serial port setup script:
# CAREFUL!  This can make some systems hang if the rc.serial script isn't
# set up correctly.  If this happens, you may have to edit the file from a
# boot disk, and/or set it as non-executable:
if [ -x /etc/rc.d/rc.serial ]; then
  sh /etc/rc.d/rc.serial start
fi

# Carry an entropy pool between reboots to improve randomness.
if [ -f /etc/random-seed ]; then
  echo "Using /etc/random-seed to initialize /dev/urandom."
  cat /etc/random-seed > /dev/urandom
fi
# Use the pool size from /proc, or 512 bytes:
if [ -r /proc/sys/kernel/random/poolsize ]; then
  dd if=/dev/urandom of=/etc/random-seed count=1 bs=$(cat /proc/sys/kernel/random/poolsize) 2> /dev/null
else
  dd if=/dev/urandom of=/etc/random-seed count=1 bs=512 2> /dev/null
fi
chmod 600 /etc/random-seed

