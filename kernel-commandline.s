        BITS 16
        %macro debug 1
        %ifdef DEBUG_MODE
        call ndebug
        db 0xFF
        call ndebug
        db %1
        %endif
        %endmacro
        %define absolute_code (0x7C00 + 4096 + 4096 + 512)
        %define absolute_end (absolute_code + (end - $$))
        %define afterend_segment (absolute_end/16)+1
        %macro set_seg 3
        mov %3, %2
        mov %1, %2
        %endmacro
main:
        mov ax, cs
        mov ds, ax

        call default_page_color
        mov si, text_string
        call print_string

init_command_input:
        call default_page_color
        mov ah, 0x0E
        mov al, ">"
        int 0x10
        mov al, " "
        int 0x10
        
        mov byte [mem_command], 0
        mov byte [mem_args], 0
        mov bx, mem_command
        xor dl, dl
input_loop:
        xor ah, ah
        int 0x16
        cmp dl, 0
        jne .skip_space_check
        cmp al, 0x20            ;space
        je .handle_space
.skip_space_check:       
        cmp al, 0x0A            ;newline
        je .handle_enter
        cmp al, 0x0D            ;CR
        je .handle_enter

        push bx
        call default_page_color
        mov ah, 0x0E
        int 0x10
        pop bx
        mov [bx], al

        inc bx

        jmp input_loop

.handle_space:   
        mov byte [bx], 0
        mov bx, mem_args
        inc dl
        push bx
        call default_page_color
        mov ah, 0x0E
        mov al, " "
        int 0x10
        pop bx
        jmp input_loop

.handle_enter:
        debug 0x0A
        call print_crlf
        push word ds            ;segment
        push word mem_command   ;offset
        push word mem_args - mem_command ;length
        call print_hex_block
        add sp, 6
        ;call wait_key
        call print_crlf
        mov byte [bx], 0
        mov word [dap.num_blocks], 8
        mov word [dap.transfer_buffer_segment], ds
        mov word [dap.transfer_buffer_offset], end
        mov dword [dap.start_block_low], 1
        mov dword [dap.start_block_high], 0
        debug 0x0B
        call print_crlf
        ;push word ds
        call drive_read
        push word ds
        push word end
        push word 6*16
        call print_hex_block
        add sp, 6
        debug 0x10
        mov bx, end
each_file:
        debug 0x11
        call print_crlf
        push word ds
        push word bx
        push word 16
        call print_hex_block
        add sp, 6
        ;call wait_key
        cmp byte [bx], 0x80
        ;; could not find file
        je init_command_input
        debug 0xF0
        cmp byte [bx], 0x81
        je each_file_inc
        debug 0xF1

        cmp byte [mem_command+0], 0
        je found_file
        debug 0xF2
        mov dl, [mem_command+0]
        cmp dl, [bx+0]
        jne each_file_inc
        debug 0xF3

        cmp byte [mem_command+1], 0
        je found_file
        debug 0xF4
        mov dl, [mem_command+1]
        cmp dl, [bx+1]
        jne each_file_inc
        debug 0xF5

        cmp byte [mem_command+2], 0
        je found_file
        debug 0xF6
        mov dl, [mem_command+2]
        cmp dl, [bx+2]
        jne each_file_inc
        debug 0xF7

        cmp byte [mem_command+3], 0
        je found_file
        debug 0xF8
        mov dl, [mem_command+3]
        cmp dl, [bx+3]
        jne each_file_inc
        debug 0xF9

        cmp byte [mem_command+4], 0
        je found_file
        debug 0xFA
        mov dl, [mem_command+4]
        cmp dl, [bx+4]
        jne each_file_inc
        debug 0xFB

        cmp byte [mem_command+5], 0
        je found_file
        debug 0xFC
        mov dl, [mem_command+5]
        cmp dl, [bx+5]
        jne each_file_inc
        debug 0xFD

        cmp byte [mem_command+6], 0
        je found_file
        mov dl, [mem_command+6]
        cmp dl, [bx+6]
        jne each_file_inc

        cmp byte [mem_command+7], 0
        je found_file
        mov dl, [mem_command+7]
        cmp dl, [bx+7]
        jne each_file_inc
        debug 0xFE
        jmp found_file
        debug 0xFF
        
each_file_inc:
        add bx, 16
        jmp each_file

found_file:
        debug 0x12
        sub sp, 8
        mov bp, sp
        mov cx, [bx+8]
        mov [bp+2], cx          ;offset low
        mov dx, [bx+10]
        mov [bp+4], dx          ;offset high

        mov cx, [bx+12]
        mov [bp+6], cx          ;size low
        mov dx, [bx+14]
        mov [bp+8], dx          ;size high

        mov word [dap.transfer_buffer_offset], 0
        mov word [dap.transfer_buffer_segment], afterend_segment
        mov cx, [bp+2]
        mov dx, [bp+4]
        mov word [dap.start_block_low], cx
        mov word [dap.start_block_low+2], dx
        mov dword [dap.start_block_high], 0
        mov ax, [bp+6]
        mov bx, [bp+8]

        shr ax, 9
        shl bx, 16-9
        or ax, bx

        inc ax
        jnc .sector_count_not_carry
        mov ax, 0xFFFF
.sector_count_not_carry: 
        mov word [dap.num_blocks], ax
        call print_crlf
        call print_crlf
        debug 0xDA
        call print_crlf
        push word ds
        push word dap
        push word 0x10
        call print_hex_block
        add sp, 6

        call drive_read

        call print_crlf
        debug 0xDA
        call print_crlf
        push word ds
        push word dap
        push word 0x10
        call print_hex_block
        add sp, 6

        call print_crlf
        debug 0x69
        call print_crlf
        push word afterend_segment
        push word 0
        push word 32
        call print_hex_block
        add sp, 6
        
        call print_crlf
        call print_crlf
        
        debug 0x14
        pushf
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        ;; we'll skip the stack segment (if it changes, then we won't have anywhere to read to get it back)
        ;; also not saving code segment; if we're here then the code segment is set correctly
        push ds
        push es
        push fs
        push gs

        mov ax, afterend_segment
        mov ds, ax
        mov ax, (afterend_segment)+0x1000
        mov es, ax
        mov ax, (afterend_segment)+0x2000
        mov fs, ax
        mov ax, (afterend_segment)+0x3000
        mov gs, ax
        ;set_seg ds, afterend_segment, ax
        ;set_seg es, (afterend_segment)+0x1000, ax
        ;set_seg fs, (afterend_segment)+0x2000, ax
        ;set_seg gs, (afterend_segment)+0x3000, ax
        call print_crlf
        debug 0x15
        call print_crlf
        push word afterend_segment
        push word 0
        push word 32
        call print_hex_block
        add sp, 6
        call (afterend_segment):0
        debug 0x16
        pop gs
        pop fs
        pop es
        pop ds
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        popf
        
        add sp, 8
        jmp init_command_input

        ;; We shouldn't ever get here...
        debug 0xDE
        debug 0xAD
        debug 0xBE
        debug 0xEF
        jmp $

text_string:    db 0x0D, 0x0A, 'This is my cool new "kernel"!', 0x0D, 0x0A, 0

        ;; Input: Data in disk_address_packet
        ;; Clobber: si, ah, dl, cf, and possibly some of the data at disk_address_packet
drive_read:
        ;debug 0xD0
        mov si, dap
        mov ah, 0x42             ; Extended read sectors from drive
        mov dl, 0x80               ; We're probably the first drive, right?
        ;debug 0xD1
        int 0x13
        ;debug 0xD2
        ret

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

default_page_color:
        mov bh, 0
        mov bl, 0x0F
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
        %ifdef DEBUG_MODE
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
        %endif
        ret
        
        ;; call with
        ;; call
        ;; db <value> ;does not get executed
        ;; code will continue from here
        ;; Clobbers: bp
ndebug:  
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
        ;; CLOBBER: none
print_hex_block:
        %ifdef debug_mode
        push ax
        push bx
        push dx
        push es
        push bp

        ;; Stack:
        ;; 0:bp
        ;; 2:es,
        ;; 4:dx,
        ;; 6:ax,
        ;; 8:bx,
        ;; 10:return pointer,
        ;; 12:length(word),
        ;; 14:pointer(word)
        ;; 16:segment(word)
        mov bp, sp
        mov es, [bp+16]         ;segment
        mov bx, [bp+14]         ;pointer/offset
        mov dx, bx
        add dx, [bp+12]         ;end pointer/offset
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

        pop bp
        pop es
        pop dx
        pop bx
        pop ax
        %endif
        ret

        ;; Waits for a keypress, and discards it
        ;; Input: none
        ;; Clobber: none
wait_key:
        push ax
        xor ah, ah
        int 0x16
        pop ax
        ret
        

        ;; Here and beyond be no code, only poor man's allocations

        times 16-(($-$$) % 16) db 0
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

        
mem_command:
        times 9 db 0
mem_args:
        times (16*9) db 0       ; I dunno, I figure 16 files seems like a lot, no one will ever need that many, right?
mem_args_end:   
end:    
