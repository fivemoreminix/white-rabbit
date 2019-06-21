    BITS 16

main:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax

        mov di, 0
        call debug

        mov word [dap.num_blocks], 1
        mov word [dap.transfer_buffer_segment], ds
        mov word [dap.transfer_buffer_offset], 512
        mov dword [dap.start_block_low], 1
        mov dword [dap.start_block_high], 0
        mov di, 1
        call debug
        call drive_read
        mov di, 2
        call debug

        ;; Hopefully, the first 32 entries of TerribleFS are in memory now
        push word ds            ;segment
        push word 512           ;ptr
        push word 128           ;len
        call print_hex_block
        add sp, 6
        mov bx, 512
.loop:
        mov di, 3
        call debug
        cmp byte [ds:bx+0], 0x80
        je end
        cmp byte [ds:bx+0], 0x81
        jge .no_fn_match
        cmp byte [ds:bx+0], "K"
        jne .no_fn_match
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
        mov di, 4
        call debug
        jne .loop
        mov di, 5
        call debug
        jmp end

.found_kern:
        mov di, 6
        call debug
        mov ax, [ds:bx+8]
        mov [dap.start_block_low], ax
        mov cx, [ds:bx+10]
        mov [dap.start_block_low+1], cx
        mov word [dap.start_block_high], 0
        mov word [dap.start_block_high+1], 0
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
        mov cx, (7C00h + 4096 + 4096 + 512)/16
        mov es, cx
        mov [dap.transfer_buffer_segment], cx
        mov word [dap.transfer_buffer_offset], 0
        call drive_read
        mov di, 7
        call debug
        mov ax, [ds:bx+12]
        mov cx, [ds:bx+14]
        ;; AX and CX are a dword again
        
        cmp cx, 0
        jne $+2
        mov ax, $0ffff           ; if the dword is >= 10000h, just set ax to FFFFh
        
        mov [.igtmtiaycsm+1], ax

        mov ah, 0Eh
        mov bh, 0h              ; page number (???)
        mov bl, 0Fh             ; white-on-black color
        xor dx, dx
        ;; index: dx
        xchg bx, dx
        ;; index: bx
.read_print_loop:      
        mov di, 8
        call debug
        mov al, [es:bx]
        xchg bx, dx
        ;; index: dx
        int 10h
        xchg bx, dx
        ;; index: bx
        ;; do stuff
        inc bx
        xchg bx, ax
        ;; index: ax
.im_going_to_modify_this_instruction_and_you_cant_stop_me:       
.igtmtiaycsm:    
        cmp ax, 0x8fff          ; 0x8fff is actually a junk value that will get written over above
        xchg bx, ax
        ;; index: bx
        jnz .read_print_loop
end:
        ;; Should probably print an error message or smth
        mov di, 9
        call debug
        call debug
        call debug
        call debug
        call debug
        call debug
        jmp $

        ;; Input: Data in disk_address_packet
        ;; Clobber: si, ah, dl, cf, and possibly some of the data at disk_address_packet
drive_read:
        mov si, dap
        mov ah, 42h             ; Extended read sectors from drive
        mov dl, 0               ; We're probably the first drive, right?
        int 13h
        ret

debug:
        call print_hex_debug
        ret

        ;; Input: al (byte to print), bh (page number), bl (color)
        ;; Clobbers: ah(set to 0Eh), al
print_hex:
        mov ah, al
        shr ah, 4
        and al, $0F
        add ax, "00"
        
        cmp ah, $3A
        jl .compare_al
        add ah, "A"-":"

.compare_al:
        cmp al, $3A
        jl .print
        add al, "A"-":"

.print:
        push ax
        xchg al, ah
        mov ah, 0Eh
        int 10h

        pop ax
        mov ah, 0Eh
        int 10h
        ret

print_hex_debug:
        push ax
        push bx
        push cx
        mov cx, di
        mov al, cl
        mov bh, 0
        mov bl, 0Fh
        call print_hex
        pop cx
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
.loop:   
        mov al, [es:bx]
        push bx
        mov bh, 0
        mov bl, 0Fh
        call print_hex
        pop bx

        mov ax, bx
        and ax, 0x0F
        cmp ax, 0x0F
        jne .loopinc
        mov al, $0D
        mov ah, 0Eh
        push bx
        mov bh, 0
        mov bl, 0Fh
        int 10h
        mov al, $0A
        int 10h
        pop bx
        
.loopinc:        
        inc bx
        cmp bx, dx
        jne .loop
        
        pop es
        pop bx
        pop ax
        ret
        
kernel_fn:
        db "KERN_BIN"
disk_address_packet:
dap:    
        db 10h                  ; size of packet
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

        
