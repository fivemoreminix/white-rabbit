    BITS 16

        jmp main
        db 0xDE, 0xAD, 0xBE, 0xEF ; just to have an obvious indicator when I show some bytes that I'm looking at the MBR
main:
	mov ax, 0x07C0		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 0x07C0		; Set data segment to where we're loaded
	mov ds, ax

        mov di, 0
        call debug

        mov word [dap.num_blocks], 1
        mov word [dap.transfer_buffer_segment], ds
        mov word [dap.transfer_buffer_offset], 512
        mov dword [dap.start_block_low], 0
        mov dword [dap.start_block_high], 0
        mov di, 1
        call debug
.do_read_drive:  
        clc
        call drive_read

        jc .carry
        mov di, 0               ;if not carry, print "00"
        call debug
        jmp .after_carry
.carry:  
        mov di, 0x0C             ;else, print "0C"
        call debug
        inc byte [drive_number]
        jmp .do_read_drive
.after_carry:    
        xchg ah, al
        mov di, ax
        call debug
        mov di, 0xFF
        call debug
        
        ;; Hopefully, the first 32 entries of TerribleFS are in memory now
        push word ds            ;segment
        push word 512           ;ptr
        push word 128           ;len
        call print_hex_block
        add sp, 6
        mov bx, 512

        jmp $

        ;; Input: Data in disk_address_packet
        ;; Clobber: si, ah, dl, cf, and possibly some of the data at disk_address_packet
drive_read:
        mov si, dap
        mov ah, 0x42             ; Extended read sectors from drive
        mov dl, [drive_number]  ; We're probably the first drive, right? (high bit means hard drive, not floppy)
        int 0x13
        ret

        ;; Input: al (byte to print), bh (page number), bl (color)
        ;; Clobbers: ah(set to 0Eh), al
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

        ;; Input: lower portion of DI
debug:  
print_hex_debug:
        push ax
        push bx
        mov ax, di
        mov bh, 0
        mov bl, 0x0F
        call print_hex
        pop bx
        pop ax
        ret

        ;; call with
        ;; push word <segment>
        ;; push word <pointer>
        ;; push word <length>
        ;; call
        ;; add sp, 6
        ;; CLOBBER: bp
print_hex_block:
        push ax                 ; As this is a debug function, I'm trying to save registers so it can be used "anywhere"
        push bx
        push dx
        push es
        
        ;; Stack:
        ;; 0:es,
        ;; 2:dx,
        ;; 4:ax,
        ;; 6:bx,
        ;; 8:return pointer,
        ;; 10:length(word),
        ;; 12:pointer(word)
        ;; 14:segment(word)

        ;; This is to grab variables passed on the stack without having to pop everything
        ;; See https://stackoverflow.com/questions/13562767/accessing-the-stack-without-popping/13564868#13564868
        mov bp, sp
        mov es, [bp+14]         ; copy segment into es
        mov bx, [bp+12]         ; copy pointer into bx
        mov dx, bx
        add dx, [bp+10]         ; add the length to dx; dx should now point to the *end* of what we're copying
.loop:   
        mov al, [es:bx]
        push bx                 ; Save bx in the stack so we can pass parameters in bh/bl
        mov bh, 0               ; Page number
        mov bl, 0x0F             ; Color: white on black
        call print_hex
        pop bx

        mov ax, bx
        and ax, 0x0F            ; This is effectively `if ptr % 16 == 15` or so I hope
        cmp ax, 0x0F
        jne .loopinc
        mov al, 0x0D             ; Print a carriage return
        mov ah, 0x0E
        push bx
        mov bh, 0
        mov bl, 0x0F
        int 0x10
        mov al, 0x0A             ; Print a new line
        int 0x10
        pop bx
        
.loopinc:        
        inc bx                  ; Increment the pointer and loop until we're done
        cmp bx, dx
        jne .loop
        
        pop es
        pop dx
        pop bx
        pop ax
        ret

drive_number:
        db 0x80
kernel_fn:
        db "KERN_BIN"
disk_address_packet:
dap:    
        db 0x10                  ; size of packet
        db 0                    ; reserved
.num_blocks:
        dw 0                    ; number of blocks to transfer
.transfer_buffer_offset:
        dw 0                    ; -> transfer buffer
.transfer_buffer_segment:
        dw 0                    ; ^
.start_block_low:
        dd 0                    ; starting absolute block number, least signficant double word
.start_block_high:
        dd 0                    ; ^ most significant double word

        
footer:
	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55               ; The standard PC boot signature

;;; After this is 4096 bytes that is reserved for the stack

        
