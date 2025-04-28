[bits 16]
[org 0x7c00]

start:
    cli
    xor ax, ax
    mov ss, ax
    mov sp, 0x7c00
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    lgdt [gdt_descriptor]

    ; Activar modo protegido
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; Salto lejano a código protegido
    jmp CODE_SEG:b32

; ===================== MODO PROTEGIDO =====================
[bits 32]

b32:
    ; Establecer segmentos de datos
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Inicializar pila
    mov ebp, 0x90000
    mov esp, ebp 

    ; Imprimir mensaje usando memoria de video
    mov ebx, message
    call print32

    jmp $           ; Bucle infinito

print32:
    pusha
    mov edx, 0xb8000     ; Dirección de memoria de video (modo texto)
.loop:
    mov al, [ebx]
    test al, al
    je .done
    mov ah, 0x0F         ; Atributo: blanco sobre negro
    mov [edx], ax
    add ebx, 1
    add edx, 2
    jmp .loop
.done:
    popa
    ret

; ===================== GDT =====================
gdt_start:

gdt_null:               ; Entrada nula
    dq 0x0000000000000000

gdt_code:               ; Segmento de código plano 4GB
    dw 0xFFFF           ; Límite bajo
    dw 0x0000           ; Base baja
    db 0x00             ; Base media
    db 10011010b        ; Acceso: presente, ring 0, código ejecutable, legible
    db 11001111b        ; Límite alto, gran, 32-bit
    db 0x00             ; Base alta

gdt_data:               ; Segmento de datos plano 4GB
    dw 0xFFFF
    dw 0x0000
    db 0x00
    ;db 10010010b        ; Acceso: presente, ring 0, datos RW
    db 10010000b        ; RW=0 → solo lectura
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; ===================== Mensaje =====================
message db 'Modo protegido OK', 0

; ===================== Firma de arranque =====================
times 510 - ($ - $$) db 0
dw 0xAA55