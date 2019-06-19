    BITS 16

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		    ; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax


	mov si, text_string	; Put string position into SI
	call print_string	; Call our string-printing routine

        mov dl, 10h
.loop:
        mov ah, 00h		; int 16h Read key press
        int 16h			; AH is the keyboard scan code and AL is the ascii code
        
        mov ah, 0Ah             ; Now we're going to write the character we just got; wow!
        mov bh, 0h              ; page number (???)
        mov cx, 1h              ; number of times to print
        int 10h

        call move_cursor_forward

        dec dl
        cmp dl, 0
        jne .loop
        

	jmp $			    ; Jump here - infinite loop!


	text_string db 'This is my cool new OS!', 0


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

move_cursor_forward:
        push ax
        push bx
        push cx
        push dx
        mov ah, 03h             ; Get cursor position and shape (shape? what?)
        mov bh, 0h              ; page 0
        int 10h                 ; DH is row, DL is column
        inc dl                  ; Move cursor forward one
        mov ah, 02h             ; set cursor position
        int 10h

.done:
        pop dx
        pop cx
        pop bx
        pop ax
        ret

	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		     ; The standard PC boot signature

        
