    BITS 16

        %macro debug 1
        %ifdef DEBUG_ENABLED
        call ndebug
        db %1
        %endif
        %endmacro
main:
	mov ax, 0x07C0		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 0x07C0		; Set data segment to where we're loaded
	mov ds, ax

        ;debug 0

        mov word [dap.num_blocks], 1
        mov word [dap.transfer_buffer_segment], ds
        mov word [dap.transfer_buffer_offset], 512
        mov dword [dap.start_block_low], 1
        mov dword [dap.start_block_high], 0
        ;debug 1
        call drive_read
        ;debug 2

        debug 0xFF
        ;; Hopefully, the first 32 entries of TerribleFS are in memory now
        %ifdef DEBUG_ENABLED
        push word ds            ;segment
        push word 512           ;ptr
        push word 128           ;len
        call print_hex_block
        add sp, 6
        %endif
        mov bx, 512
.loop:
        ;debug 3
        
        cmp byte [ds:bx+0], 0x80
        je end
        ;debug 0x1F
        cmp byte [ds:bx+0], 0x81
        jle .no_fn_match
        ;debug 0x20
        cmp byte [ds:bx+0], "K"
        jne .no_fn_match
        ;debug 0x21
        cmp byte [ds:bx+1], "E"
        jne .no_fn_match
        cmp byte [ds:bx+2], "R"
        jne .no_fn_match
        cmp byte [ds:bx+3], "N"
        jne .no_fn_match
        cmp byte [ds:bx+4], "_"
        jne .no_fn_match
        cmp byte [ds:bx+5], "B"
        jne .no_fn_match
        cmp byte [ds:bx+6], "I"
        jne .no_fn_match
        cmp byte [ds:bx+7], "N"
        jne .no_fn_match

        ;; [ds:bx+8] now points to file sector offset dword followed by file size dword
        jmp .found_kern

.no_fn_match:       
        add bx, 16
        cmp bx, 1024
        ;debug 4
        jne .loop
        ;debug 5
        jmp end

.found_kern:
        debug 6
        mov ax, [ds:bx+8]
        mov [dap.start_block_low], ax
        mov cx, [ds:bx+10]
        mov [dap.start_block_low+2], cx
        mov word [dap.start_block_high], 0
        mov word [dap.start_block_high+2], 0
        mov ax, [ds:bx+12]
        mov cx, [ds:bx+14]
        ;; AX(LS) and CX(MS) form a dword, we need to divide it by 512 (2^9)
        ;; and then truncate to a word
        shr ax, 9
        shl cx, 16-9
        or ax, cx

        inc ax
        ;; AX should now be the number of blocks to transfer,
        ;; BX still points to the FS entry,
        ;; CX we don't care about anymore

        mov [dap.num_blocks], ax
        mov cx, (0x7C00 + 4096 + 4096 + 512)/16
        mov es, cx
        mov [dap.transfer_buffer_segment], cx
        mov word [dap.transfer_buffer_offset], 0

        %ifdef ENABLE_DEBUG
        push word ds
        push word dap
        push word 0x0010        ;dap packet is 0x10 bytes
        call print_hex_block
        add sp, 6

        clc
        %endif

        call drive_read

        %ifdef ENABLE_DEBUG
        jnc .data_read_not_carry
        debug 0x1C
        jmp .data_read_continue
.data_read_not_carry:
        debug 0x0C
.data_read_continue:     

        call print_crlf
        %endif
        call ((0x7C00 + 4096 + 4096 + 512)/16):0
end:
        ;; Should probably print an error message or smth
        debug 0x99
        debug 0x99
        jmp $

        ;; Input: Data in disk_address_packet
        ;; Clobber: si, ah, dl, cf, and possibly some of the data at disk_address_packet
drive_read:
        mov si, dap
        mov ah, 0x42             ; Extended read sectors from drive
        mov dl, 0x80               ; We're probably the first drive, right?     
        int 0x13
        ret
        %ifdef DEBUG_ENABLED
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

        ;; call with
        ;; push word <segment>
        ;; push word <pointer>
        ;; push word <length>
        ;; call
        ;; add sp, 6
        ;; CLOBBER: bp
print_hex_block:
        push ax
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
        mov bp, sp
        mov es, [bp+14]
        mov bx, [bp+12]
        mov dx, bx
        add dx, [bp+10]
        call print_crlf
.loop:   
        mov al, [es:bx]
        push bx
        mov bh, 0
        mov bl, 0x0F
        call print_hex
        pop bx

        mov ax, bx
        and ax, 0x0F
        cmp ax, 0x0F
        jne .loopinc
        call print_crlf
        
.loopinc:        
        inc bx
        cmp bx, dx
        jne .loop
        
        call print_crlf

        pop es
        pop dx
        pop bx
        pop ax
        ret

        %endif
        
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

;;; After this is 4096 bytes that is reserved for the stack, maybe??????

        
