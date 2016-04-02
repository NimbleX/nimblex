**NimbleX** is a small but versatile operating system which is able to boot from CD, flash memory (USB pens or Mp3 players) and even from the network.

The key features of NimbleX are:
- Very fast even on slow disks. The OS is decompressed on the fly so IO is minimized.
- Indestructible: The OS is read only and only the changes get written to RAM or disk.
- Full featured. Out of the box NimbleX comes with over 1000 packages.

The main limitation of NimbleX is that it doesn't have a user friendly installer so contributions are welcomed.

This repo contains the build scripts for creating the NimbleX Linux distribution from inside NimbleX or Slackware.

In order to make it more maintainable, the distribution returned to using most of the libraries from Slackware but it also has major differences.
NimbleX was built around AUFS which does all the magic in intramfs and uses systemd for initialization.

To build everything it should be enough to run `./08-Service.sh world 64` but it was only tested on one computer so far.
