        BITS 16
        %macro debug 1
        call ndebug
        db %1
        %endmacro
main:
        mov ax, cs
        mov ds, ax

        mov bh, 0
        mov bl, 0x0F
        mov si, text_string
        call print_string
        jmp $

text_string:    db 0x0D, 0x0A, 'This is my cool new "kernel"!', 0x0D, 0x0A, 0

        ;; Input: si (start index of string), bh (page number), bl (color)
        ;; Clobbers: ah, al, si
print_string:			; Routine: output string in SI to screen
	mov ah, 0Eh		    ; int 10h 'print char' function

.repeat:
	lodsb			    ; Get character from string
	cmp al, 0
	je .done		    ; If char is zero, end of string
	int 0x10  		    ; Otherwise, print it
	jmp .repeat

.done:
	ret

        ;; Input: al (byte to print), bh (page number), bl (color)
        ;; Clobbers: ah(set to 0x0E), al
print_hex:
        mov ah, al
        shr ah, 4
        and al, 0x0F
        add ax, "00"
        
        cmp ah, 0x3A
        jl .compare_al
        add ah, "A"-":"

.compare_al:
        cmp al, 0x3A
        jl .print
        add al, "A"-":"

.print:
        push ax
        xchg al, ah
        mov ah, 0x0E
        int 0x10

        pop ax
        mov ah, 0x0E
        int 0x10
        ret
print_crlf:
        pushf
        push ax
        push bx

        mov ah, 0x0E
        mov bh, 0
        mov bl, 0x0F
        mov al, 0x0A
        int 0x10
        mov al, 0x0D
        int 0x10
        
        pop bx
        pop ax
        popf
        ret
        
        ;; call with
        ;; call
        ;; db <value> ;does not get executed
        ;; code will continue from here
        ;; Clobbers: bp
ndebug:  
print_hex_debug:
        ;; return pointer: 2
        pushf                   ; 2
        push ax                 ; 2
        push bx                 ; 2
        push cx                 ; 2
        ;; sp+10 is the return pointer
        mov bp, sp
        mov bx, [ss:bp+8]
        mov al, [cs:bx]
        mov bh, 0
        mov bl, 0x0F
        call print_hex
        inc word [ss:bp+8]
        pop cx
        pop bx
        pop ax
        popf
        ret
