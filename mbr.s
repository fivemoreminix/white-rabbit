    BITS 16

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax

        ;; http://www.ctyme.com/intr/rb-0607.htm
        

footer:
	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		     ; The standard PC boot signature

        
