default rel                     ; Use RIP-relative addressing for global labels by default

section .data
    sensor_byte db -12          ; Signed 8-bit byte: -12 (0xF4 in two's complement hex)
    drone_rpm   dq 1200, 1550, 1800, 2100 ; Array of four 64-bit quadwords (8 bytes each)

section .bss
    telemetry_out resq 1        ; Reserve one 64-bit quadword (8 bytes) in uninitialized RAM

section .text
    global _start

_start:
    ; 1. Zero-Extension vs. Sign-Extension of 0xF4 (-12 signed / 244 unsigned)
    movzx rax, byte [sensor_byte] ; Zero-extends 0xF4 -> RAX = 0x00000000000000F4 (244)
    movsx rbx, byte [sensor_byte] ; Sign-extends 0xF4 -> RBX = 0xFFFFFFFFFFFFFFF4 (-12)

    ; 2. LEA (Pointer Calculation) vs. MOV (Memory Dereference)
    lea rdi, [drone_rpm]          ; RDI = memory address of drone_rpm[0] (no RAM read)
    mov rsi, [drone_rpm]          ; RSI = 1200 (value stored at drone_rpm[0] in RAM)

    ; 3. Base + (Index * Scale) + Displacement Addressing
    mov rcx, 2                    ; Index = 2 (targeting the 3rd element, drone_rpm[2])
    mov rdx, [rdi + rcx*8]        ; RDX = *(RDI + 2*8) = 1800
    mov r8,  [rdi + rcx*8 + 8]    ; R8  = *(RDI + 2*8 + 8) = drone_rpm[3] = 2100

    ; 4. Using LEA for fast arithmetic without altering RFLAGS
    lea r9, [rdx + rdx*4 + 50]    ; R9 = 1800 + (1800 * 4) + 50 = 9050 in a single cycle

    ; 5. Writing to RAM with an explicit width specifier
    mov qword [telemetry_out], r9 ; Store 64-bit value 9050 into telemetry_out in .bss

    ; 6. Exit cleanly, passing drone_rpm[2] / 100 (18) in RDI
    mov rdi, 18
    mov rax, 60                   ; sys_exit
    syscall