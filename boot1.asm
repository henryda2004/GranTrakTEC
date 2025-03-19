[bits 16]
[org 0x7C00]

start:
    ; ----------------------------------------------------------------
    ; Deshabilitamos interrupciones y configuramos la pila
    cli
    xor ax, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; ----------------------------------------------------------------
    ; Cargar la segunda etapa (stage) en 0x1000:0
    ; ----------------------------------------------------------------
    mov ax, 0x1000   ; Segmento donde cargaremos Stage 2
    mov es, ax
    xor bx, bx       ; Offset = 0 (ES:BX → 0x1000:0)

    ; AH = 2 (leer sectores), AL = #sectores, CH = cilindro, DH = cabeza, CL = sector
    mov ah, 0x02     ; Función "Leer sectores" de int 13h
    mov al, 8        ; Leer 8 sectores (4KB - suficiente para un programa más grande)
    mov ch, 0        ; Cilindro = 0
    mov dh, 0        ; Cabeza = 0
    mov cl, 2        ; Sector = 2 (sector 1 es este boot, sector 2 es "Stage 2")
    xor dl, dl       ; DL=0 → floppy A: (o 0x80 si fuese disco duro)
    int 0x13
    jc load_error    ; Si falla la lectura, saltamos a error

    ; Todo OK, saltar a Stage 2 en 0x1000:0
    jmp 0x1000:0x0000

load_error:
    ; Mostrar un mensaje de error más descriptivo
    mov si, error_msg
    call print_string
    hlt              ; Detener la máquina
    jmp load_error   ; Bucle infinito en caso de error

; Subrutina para imprimir un string terminado en 0
print_string:
    mov ah, 0x0E     ; Función de teletipo BIOS
    xor bh, bh       ; Página 0
.loop:
    lodsb            ; Cargar byte de [SI] en AL y incrementar SI
    test al, al      ; ¿Es cero (fin de cadena)?
    jz .done         ; Sí, terminamos
    int 0x10         ; No, mostrar carácter
    jmp .loop        ; Siguiente carácter
.done:
    ret

; Mensaje de error
error_msg db 'Error al cargar sectores!', 0

; Rellenar hasta 510 bytes
times 510 - ($ - $$) db 0

; Firma de boot sector (2 bytes finales → 0xAA55)
dw 0xAA55