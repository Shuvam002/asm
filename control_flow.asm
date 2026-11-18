default rel

section .data
    motor_rpms dq 1450, 2350, 0, 18446744073709551615 ; 4 unsigned 64-bit values

section .text
    global _start

_start:
    lea rbx, [motor_rpms]               ; RBX = base address of motor_rpms array
    xor rcx, rcx                        ; RCX = loop counter i = 0

.loop_print:
    cmp rcx, 4                          ; Check if i >= 4
    jae .exit                           ; Exit loop after printing all 4 elements

    mov rdi, [rbx + rcx*8]              ; Load motor_rpms[i] into 1st argument register RDI
    call print_uint                     ; Print RDI as an unsigned integer (preserves RCX & RBX!)

    inc rcx                             ; i++
    jmp .loop_print

.exit:
    xor rdi, rdi                        ; Exit code 0
    mov rax, 60                         ; sys_exit
    syscall

; -----------------------------------------------------------------------------
; Procedure: print_uint
; Input:     RDI = 64-bit unsigned integer to print (appends newline '\n')
; Preserves: RAX, RCX, RDX, RSI, RDI, R11 (safe to call inside any active loop)
; -----------------------------------------------------------------------------
print_uint:
    ; 1. Prologue: Create stack frame and allocate 32-byte local character buffer
    push rbp
    mov rbp, rsp
    sub rsp, 32                         ; Reserve [rbp-32 .. rbp-1] on the stack

    ; 2. Preserve registers modified by division and sys_write
    push rax
    push rcx
    push rdx
    push rsi
    push rdi
    push r11                            ; Linux syscall clobbers RCX and R11

    ; 3. Point RSI to the end of the stack buffer and insert newline '\n'
    lea rsi, [rbp - 1]
    mov byte [rsi], 10                  ; ASCII 10 = '\n'

    mov rax, rdi                        ; Dividend = number to print
    mov rcx, 10                         ; Divisor = 10

.convert_loop:
    xor rdx, rdx                        ; Clear upper 64 bits of dividend (RDX:RAX)
    div rcx                             ; RAX = quotient, RDX = remainder (0..9)
    add dl, '0'                         ; Convert numeric digit (0..9) to ASCII ('0'..'9')
    dec rsi                             ; Step backward 1 byte in stack buffer
    mov [rsi], dl                       ; Write ASCII byte onto the stack
    test rax, rax                       ; Check if quotient reached 0
    jnz .convert_loop                   ; Continue until all digits are extracted

    ; 4. Calculate string length and print via sys_write(stdout, rsi, length)
    lea rdx, [rbp]                      ; RDX = end of buffer address
    sub rdx, rsi                        ; RDX = total bytes written (digits + '\n')

    mov rax, 1                          ; Syscall 1 = sys_write
    mov rdi, 1                          ; File descriptor 1 = stdout
    syscall

    ; 5. Epilogue: Restore registers in reverse order and tear down stack frame
    pop r11
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rax

    mov rsp, rbp                        ; Deallocate 32-byte stack buffer
    pop rbp                             ; Restore caller's RBP
    ret                                 ; Pop return address into RIP