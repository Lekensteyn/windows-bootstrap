# Windows Bootstrap
This repository contains scripts and tools to automate installation and
configuration of a Windows 7 machine for use in QEMU. The scripts are intended
to run under a Linux system and will output an ISO image containing an
`AutoUnattend.xml` file which will answer Setup questions.

**Note: the generated iso will wipe your disk without questions!**

The scripts are written with a 64-bit iso, but can be adopted for 32-bit
installations if wanted.

## Requirements
mkisofs is needed by makeiso.sh to create a iso file (part of cdrkit, package
genisomage on Ubuntu).

A Windows 7 iso is (obviously) needed to start the installation. Tested with:

    Windows 7 Ultimate x64 English
    http://msft.digitalrivercontent.net/win/X17-59465.iso
    size 3320903680 bytes
    md5  c9f7ecb768acb82daacf5030e14b271e
    sha1 36ae90defbad9d9539e649b193ae573b77a71c83

Tested with QEMU 2.0.0 on Ubuntu 14.04 LTS, QEMU 2.1 on Arch Linux.

## Usage
Example shell script:

    winiso=X17-59465.iso
    diskimg=win7.qcow2
    automateiso=bootstrap.iso

    # Create the bootstrap image
    # Second argument can be basic, premium, pro or ultimate (see from-tpl.sh)
    ./makeiso.sh "$automateiso" basic

    # Create QEMU disk image
    qemu-img create -f qcow2 "$diskimg" 12G

    # Start the installation
    qemu-system-x86_64 \
        -machine pc,accel=kvm -m 4G -smp threads=2 -vga std \
        -usb -usbdevice tablet \
        -drive if=none,aio=native,discard=unmap,file="$diskimg",id=vd0 \
        -device virtio-scsi-pci -device scsi-disk,drive=vd0 \
        -drive media=cdrom,aio=native,file="$winiso" \
        -drive media=cdrom,aio=native,file="$automateiso" \
        -net user,id=user0 -net nic,model=virtio,id=vnet0

For reference, installation on an i7-3770 with all three files in a 18GiB tmpfs
took about 4m30s to 5m following the above commands. The disk space utilization
as measured using virt-df is somehow the same for all editions (Home Basic, Home
Premium, Professional and Ultimate) and are about 7.90 GiB. This includes the
pagefile, once rebooted about 6.87-7.00 GiB will be in use.

Do not forget to install updates which will take a lot more time and disk space.

## Configuration details
Many Windows features have been disabled, see
[AutoUnattended-tpl.xml](AutoUnattended-tpl.xml) for details. Overview of
settings:

 - Disk size: 12 GiB (page file disabled).
 - Additional drivers: virtio (netkvm, vioscsi, viostor).
 - Default user: User, default password: Password.
 - Locale: en-US (mostly, using userLocale nl-NL for Euros).
 - Computer name: QEMU
 - Resolution: 1280x800 (color depth: 32).
 - Timezone: UTC+1 (Europe/Amsterdam)
 - Homepage: http://10.0.2.2:8888/ (10.0.2.2 is the host IP address when QEMU
   user networking is in use).

On post-installation, `wsim\Firstrun\setup.ps1` gets executed which:

 - Show hidden and system files, unhide file extensions.
 - Display "Computer" icon on desktop.
 - Disable page files and hibernation.
 - If Windows is not already activated, execute the `slactivate` program at
   `wsim\Firstrun\slactivate` (with an extension such as .cmd, .exe, etc.).  If
   that file exists and runs a zero status code, then the system will reboot to
   complete the activation.

## Known issues
The bootstrap image for the Basic edition shows an error after the first reboot
("Completing installation") which makes the installation not quite unattended.

## Third-party software
The virtio drivers have been retrieved from
http://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/

## Copyright
Windows is a trademark blabla Microsoft blabla registered US blabla bla.

The Windows virtio drivers are GPLd, see
http://www.linux-kvm.org/page/WindowsGuestDrivers for details.

The scripts and configuration files are provided under the terms in the MIT
license (see LICENSE.txt for details).
