        BITS 16

        mov si, text_string
        call print_string
        retf

text_string:    db 0x0D, 0x0A, 'This is a test program!', 0x0D, 0x0A, 0

        
        ;; Input: si (start index of string), bh (page number), bl (color)
        ;; Clobbers: ah, al, si
print_string:			; Routine: output string in SI to screen
	mov ah, 0x0E		    ; int 10h 'print char' function

.repeat:
	lodsb			    ; Get character from string
	cmp al, 0
	je .done		    ; If char is zero, end of string
	int 0x10  		    ; Otherwise, print it
	jmp .repeat

.done:
	ret
