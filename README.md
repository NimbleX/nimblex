<h1 align="center">NimbleX</h1>

<p align="center">
  <strong>A full Linux workstation on a USB stick — boots in seconds, runs without installation, and cannot be broken.</strong>
</p>

<p align="center">
  <img alt="Base" src="https://img.shields.io/badge/base-Slackware--current-6c4">
  <img alt="Init" src="https://img.shields.io/badge/init-systemd-blue">
  <img alt="FS" src="https://img.shields.io/badge/fs-AUFS%20%2B%20squashfs-orange">
  <img alt="Arch" src="https://img.shields.io/badge/arch-x86__64-lightgrey">
  <img alt="Boot" src="https://img.shields.io/badge/boot-USB%20%7C%20PXE-9cf">
</p>

<p align="center">
  <a href="https://www.nimblex.net">Website</a> ·
  <a href="http://packages.nimblex.net/nimblex/">Packages</a> ·
</p>

---

## What is NimbleX?

NimbleX is a fast, modern Linux distribution you carry on a USB stick. Plug it
into any x86-64 machine, boot, and within seconds you have a complete graphical
workstation in front of you — no installation, no partitioning, no trace left
behind on the host. Take the stick out and the machine is exactly as you found it.

Built on Slackware-current and powered by systemd, NimbleX stacks its filesystem
out of compressed squashfs modules with AUFS. The result is a system that is
lightweight enough to boot from a USB stick yet complete enough to replace a
permanent desktop.

## Why NimbleX?

### Indestructible by design

The base system is read-only. Every change you make — installing software,
editing configuration, breaking things on purpose — lands on a writable
overlay in RAM or on disk. Reboot, and you are back to a known-good system.
You can experiment freely; there is nothing you can permanently damage.

### You are root

NimbleX trusts you with your own computer. There are no sudo prompts, no
artificial barriers between you and the system. If you want to inspect a
device, edit a system file, or load a kernel module, you just do it. It is
your machine, after all.

### Batteries included

A single ISO ships with more than 1000 packages ready to use: a full KDE
Plasma desktop (or KDE 4, or a lean i3wm setup), Firefox, GIMP, MPlayer,
LibreOffice-class tooling, NetworkManager, PipeWire, libvirt + QEMU, a full
development toolchain, and the usual Unix utilities you expect to find on a
real workstation. Plug it in and start working.

### Lightweight and fast

Modules are compressed with `xz` and decompressed on the fly, so NimbleX
boots quickly even from slow media and stays nimble in memory. The whole
system is modular: drop a module you do not need, add one you do, and the
next boot reflects the change.

### Truly portable

A USB stick or PXE network boot is all you need. Run entirely from RAM and
the host machine is left completely untouched. Keep a persistent overlay on
the stick and your settings, files, and installed packages travel with you
wherever you go. When you are ready to commit, install to disk — same system,
no reinstall.

## Highlights

- **Boot anywhere** — USB stick or PXE network boot, no installation needed.
- **Read-only base, writable overlay** — break it, reboot it, it is fine.
- **Modular squashfs** — every part of the OS is a module you can swap.
- **Multiple desktops** — KDE Plasma 5, KDE 4, or i3wm.
- **Live or installed** — run from RAM, or install to disk when you are ready.
- **Slackware-current under the hood** — fresh packages, classic Unix feel.
- **Systemd, NetworkManager, PipeWire, libvirt, full devel stack** — out of the box.

## Quick start (building from source)

NimbleX is a build system. The scripts download Slackware packages, clean
them up, stack them with AUFS, and squash the result into the modules that
make up the live ISO.

Build everything, package an ISO, and launch a test VM:

```bash
./08-Service.sh big-world 64
```

Build modules only (no ISO):

```bash
./08-Service.sh world 64
```

Repackage an existing build into a fresh ISO and boot it:

```bash
./08-Service.sh small-world 64
```

Rebuild a single module:

```bash
./04-Apps.sh world
```

## Build modules

| Script           | Purpose                                    |
| ---------------- | ------------------------------------------ |
| `01-Core.sh`     | Kernel, core libs, systemd, networking     |
| `02-Xorg.sh`     | X11, graphics drivers, Qt/GTK              |
| `03-Libs.sh`     | Extra multimedia libs (currently disabled) |
| `04-Apps.sh`     | Firefox, GIMP, MPlayer, and other apps     |
| `05-KDE.sh`      | KDE 4 desktop                              |
| `07-Devel.sh`    | Compilers, headers, development tools      |
| `08-Service.sh`  | Orchestration, ISO creation, VM testing    |
| `09-Multilib.sh` | 32-bit compatibility on 64-bit systems     |
| `10-Virtual.sh`  | QEMU, libvirt, virt-manager                |
| `11-KDE5.sh`     | KDE Plasma 5 desktop                       |

## How it works

- Packages come from Slackware-current and a handful of NimbleX-specific
  repositories.
- Each module is built into its own directory, cleaned of docs, locales, and
  headers, then squashed with `xz`.
- AUFS stacks the modules at build time so `ldconfig` can run across the
  full system before each module is sealed.
- At runtime the same squashfs modules are stacked again on top of a
  writable overlay — that is what makes the live system feel like a real,
  fully-installed Linux.

## Requirements (for building)

- A host running **NimbleX or Slackware** with `installpkg` available.
- **AUFS** support in the kernel (used during the build, not just at runtime).
- **Root** privileges (mount, chroot, package install).
- Optional: `libvirt` + QEMU for the test VM targets.

## Configuration

- Override the package mirror by creating `ftp-credentials` (gitignored)
  with `USERNAME`, `PASSWORD`, and `HOSTNAME`.
- Pass `WGET_OPTS=""` for verbose downloads.
- Full build internals, gotchas, and conventions live in
  [`AGENTS.md`](./AGENTS.md).

## Status

NimbleX is maintained as a one-person hobby distribution and tracks
Slackware-current. The biggest open gap is a friendly graphical installer —
contributions there are very welcome.

## Links

- Project site: <https://www.nimblex.net>
- NimbleX packages: <http://packages.nimblex.net/nimblex/>
