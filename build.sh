#!/usr/bin bash
nasm -f bin -o white_rabbit.bin fuckmewhatdowecallit.s
cp disk_images/mikeos.flp white_rabbit.flp
dd status=noxfer conv=notrunc if=white_rabbit.bin of=white_rabbit.flp
qemu-system-i386 -fda white-rabbit.flp
