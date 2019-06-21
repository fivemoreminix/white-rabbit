.PHONY: qemu run clean

white_rabbit.flp: mbr.bin terriblefs.bin
	dd status=noxfer if=/dev/zero of=white_rabbit_tmp.flp bs=1K count=1440
	dd status=noxfer conv=notrunc if=mbr.bin of=white_rabbit_tmp.flp
	dd status=noxfer conv=notrunc if=terriblefs.bin of=white_rabbit_tmp.flp bs=512 seek=1
	mv white_rabbit_tmp.flp white_rabbit.flp

qemu: white_rabbit.flp
	qemu-system-i386 -drive format=raw,file=white_rabbit.flp,if=ide,index=0

run: qemu

clean:
	rm white_rabbit.bin white_rabbit.lst white_rabbit.flp mbr.bin mbr.lst white_rabbit_tmp.flp

%.bin %.lst: %.s
	nasm -f bin -o $*.bin $*.s -l $*.lst
#nasm -f bin -o white_rabbit.bin fuckmewhatdowecallit.s

make-terriblefs.mk: make-terriblefs.rb
	ruby make-terriblefs.rb makefile > make-terriblefs.mk

-include make-terriblefs.mk
