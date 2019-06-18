# white-rabbit
Some weird operating system we're making.

# Building
```bash
nasm -f bin -o white_rabbit.bin fuckmewhatdowecallit.s
cp disk_images/mikeos.flp white_rabbit.flp
dd status=noxfer conv=notrunc if=white_rabbit.bin of=white_rabbit.flp
qemu-system-i386 -fda myfirst.flp
```

## To Generate ISO image:
Make a new directory called `cdiso` and move the `myfirst.flp` file into it. Then:
```bash
mkisofs -o myfirst.iso -b myfirst.flp cdiso/
```