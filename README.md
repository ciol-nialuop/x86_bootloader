x86_bootloader
==============

simple X86 asm bootloader

This is a basic x86 bootloader
- Load 'kernel' from 2nd sector
- Load Global Descriptor Table
- Switch to protected mode
- Execute kernel

build:
nasm -o bootstrap.bin bootstrap.asm

generate image:
dd status=noxfer conv=notrunc if=bootstrap.bin of=bootstrap.flp

run (qemu):
qemu-system-i386 -fda bootstrap.flp

contact: loic.poulain@gmail.com
