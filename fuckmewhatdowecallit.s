    BITS 16

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax


	mov si, text_string	; Put string position into SI
	call print_string	; Call our string-printing routine

        mov bh, 0h              ; page number (???)
        mov bl, 0Fh             ; white-on-black color
.loop:
        mov ah, 00h		; int 16h Read key press
        int 16h			; AH is the keyboard scan code and AL is the ascii code

        mov ah, 0Eh             ; print character
        
        cmp al, 0Dh             ; carriage return; what bios gives for the enter key
        jne .print_char

        mov al, 0Ah             ; Newline/linefeed
        int 10h
        mov al, 0Dh

.print_char:     
        int 10h                 ; Now we're going to write the character we just got; wow!

        jmp .loop
        
.end:
	jmp $		        ; Jump here - infinite loop!


text_string:    db 'This is my cool new OS!', $0A, $0D, 0

        ;; Input: si (start index of string), bh (page number), bl (color)
        ;; Clobbers: ah, al, si
print_string:			; Routine: output string in SI to screen
	mov ah, 0Eh		    ; int 10h 'print char' function

.repeat:
	lodsb			    ; Get character from string
	cmp al, 0
	je .done		    ; If char is zero, end of string
	int 10h			    ; Otherwise, print it
	jmp .repeat

.done:
	ret

footer:
	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		     ; The standard PC boot signature

        
