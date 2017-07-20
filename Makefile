all: bootstrap kernel image

bootstrap: bootstrap.asm
	nasm -f bin -o bootstrap.bin bootstrap.asm

kernel: kernel.asm
	nasm -f bin -o kernel.bin kernel.asm

image: kernel bootstrap
	# FIRST SECTOR
	dd status=noxfer conv=notrunc bs=512 seek=0 if=bootstrap.bin of=boot.flp
	#SECOND SECTOR
	dd status=noxfer conv=notrunc bs=512 seek=1 if=kernel.bin of=boot.flp

clean:
	rm -f boot.flb
	rm -f *.bin
