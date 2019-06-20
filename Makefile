.PHONY: qemu run clean

white_rabbit.flp: mbr.bin
	dd status=noxfer if=/dev/zero of=white_rabbit_tmp.flp bs=1K count=1440
	dd status=noxfer conv=notrunc if=mbr.bin of=white_rabbit_tmp.flp
	mv white_rabbit_tmp.flp white_rabbit.flp

qemu: white_rabbit.flp
	qemu-system-i386 -drive format=raw,file=white_rabbit.flp 

run: qemu

clean:
	rm white_rabbit.bin white_rabbit.lst white_rabbit.flp mbr.bin mbr.lst white_rabbit_tmp.flp

%.bin %.lst: %.s
	nasm -f bin -o $*.bin $*.s -l $*.lst
#nasm -f bin -o white_rabbit.bin fuckmewhatdowecallit.s
