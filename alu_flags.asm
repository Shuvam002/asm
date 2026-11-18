section .text
    global _start

_start:
    ; 1. Trigger Unsigned Carry (CF) vs Signed Overflow (OF) on an 8-bit register (AL)
    mov al, 255                 ; AL = 0xFF (255 unsigned, -1 signed)
    add al, 1                   ; 255 + 1 wraps AL to 0x00!
                                ; Watch eflags show: [ CF PF ZF IF ] (Unsigned overflow + Zero!)

    mov al, 127                 ; AL = 0x7F (+127 max positive 8-bit signed integer)
    add al, 1                   ; 127 + 1 = 0x80 (-128 in signed 8-bit!)
                                ; Watch eflags show: [ PF SF IF OF ] (Signed overflow + Negative!)

    ; 2. Two-Operand Signed Multiplication & Signed Division with CQO
    mov rax, -45                ; Load -45 into RAX
    imul rax, 4                 ; RAX = -45 * 4 = -180 (2-operand IMUL doesn't touch RDX)
    cqo                         ; Sign-extend RAX (-180) into RDX:RAX (RDX becomes 0xFFFFFFFFFFFFFFFF)
    mov rbx, 7                  ; Divisor = 7
    idiv rbx                    ; Divide -180 by 7 -> RAX = -25 (quotient), RDX = -5 (remainder)

    ; 3. Arithmetic Right Shift (SAR) vs Logical Right Shift (SHR) on negative numbers
    mov r8, -64                 ; R8 = -64 (0xFFFFFFFFFFFFFFC0)
    sar r8, 2                   ; Signed divide by 2^2 (4) -> R8 = -16 (preserves sign bit!)
    mov r9, -64                 ; R9 = -64 (0xFFFFFFFFFFFFFFC0)
    shr r9, 2                   ; Unsigned shift right -> fills top bits with 0 (huge positive number!)

    ; 4. Hardware Bit Masking: Set bit 3, Clear bit 0, Toggle bit 1
    mov r10b, 0b00000011        ; Start with bits 0 and 1 ON (value = 3)
    or  r10b, 0b00001000        ; Set bit 3 ON   -> 0b00001011 (11)
    and r10b, 0b11111110        ; Clear bit 0 OFF -> 0b00001010 (10)
    xor r10b, 0b00000010        ; Toggle bit 1   -> 0b00001000 (8)

    ; 5. Exit passing R10 (8) as status code
    movzx rdi, r10b
    mov rax, 60
    syscall