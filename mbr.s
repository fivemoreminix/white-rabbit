    BITS 16

main:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax

        mov word [dap.num_blocks], 1
        mov word [dap.transfer_buffer_segment], ds
        mov word [dap.transfer_buffer_offset], 512
        mov dword [dap.start_block_low], 1
        mov dword [dap.start_block_high], 0
        call drive_read

        ;; Hopefully, the first 32 entries of TerribleFS are in memory now
        mov bx, 512
.loop:
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
        jne .loop
        jmp end

.found_kern:
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
        mov [dap.transfer_buffer_offset], 0
        call drive_read
        mov ax, [ds:bx+12]
        mov cx, [ds:bx+14]
        
end:
        ;; Should probably print an error message or smth
        loop $

        ;; Input: Data in disk_address_packet
        ;; Clobber: si, ah, dl, cf, and possibly some of the data at disk_address_packet
drive_read:
        mov si, dap
        mov ah, 42h             ; Extended read sectors from drive
        mov dl, 0               ; We're probably the first drive, right?
        int 13h
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

        
