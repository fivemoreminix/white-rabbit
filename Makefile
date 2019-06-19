.PHONY: qemu run

white_rabbit.flp: white_rabbit.bin
	cp disk_images/mikeos.flp white_rabbit.flp
	dd status=noxfer conv=notrunc if=white_rabbit.bin of=white_rabbit.flp

qemu: white_rabbit.flp
	qemu-system-i386 -fda white_rabbit.flp

run: qemu

white_rabbit.bin: fuckmewhatdowecallit.s
	nasm -f bin -o white_rabbit.bin fuckmewhatdowecallit.s
