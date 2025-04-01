; =============================================================================
; BOOTLOADER BÁSICO - PRIMERA ETAPA
; =============================================================================
; Este bootloader se encarga de inicializar el sistema y cargar la segunda 
; etapa desde el disco a la memoria.
; =============================================================================
[bits 16] ; Indicamos que usamos modo real de 16 bits
[org 0x7C00] ; Dirección de carga del bootloader por el BIOS

start:
    ; =============================================================================
    ; INICIALIZACIÓN DEL SISTEMA
    ; =============================================================================
    ; Deshabilitamos interrupciones y configuramos la pila
    cli             ; Deshabilita interrupciones durante configuración inicial
    xor ax, ax      ; Pone AX en 0 (más eficiente que mov ax, 0) 
    mov ss, ax      ; Establece segmento de pila en 0
    mov sp, 0x7C00  ; Puntero de pila justo debajo del bootloader
    sti             ; Habilita interrupciones nuevamente

    ; =============================================================================
    ; CARGA DE LA SEGUNDA ETAPA
    ; =============================================================================
    ; Cargar la segunda etapa (stage) en 0x1000:0
    ; La dirección física será 0x1000 * 16 + 0 = 0x10000
    mov ax, 0x1000   ; Segmento donde cargaremos Stage 2
    mov es, ax
    xor bx, bx       ; Offset = 0 (ES:BX → 0x1000:0)

    ; Configuración para la interrupción de lectura de disco (INT 13h)
    ; AH = 2 (leer sectores), AL = #sectores, CH = cilindro, DH = cabeza, CL = sector
    mov ah, 0x02     ; Función "Leer sectores" de int 13h
    mov al, 8        ; Leer 8 sectores (4KB en total)
    mov ch, 0        ; Cilindro = 0
    mov dh, 0        ; Cabeza = 0
    mov cl, 2        ; Sector = 2 (sector 1 es este boot, sector 2 es "Stage 2")
    xor dl, dl       ; DL=0 → floppy A: (o 0x80 si fuese disco duro)
    int 0x13         ; Ejecuta la interrupción de BIOS para lectura
    jc load_error    ; Si el flag de acarreo está activo, hubo un error

    ; =============================================================================
    ; TRANSFERENCIA DE CONTROL
    ; =============================================================================
    ; Todo OK, saltar a Stage 2 en 0x1000:0
    jmp 0x1000:0x0000

; =============================================================================
; RUTINA DE MANEJO DE ERROR
; =============================================================================
load_error:
  mov ah, 0x0E     ; Función de teletipo BIOS para mostrar un carácter
  mov al, 'E'      ; Carácter 'E' para indicar error
  int 0x10         ; Interrupción de video para mostrar el carácter
  hlt              ; Detener la CPU
  jmp load_error   ; Bucle infinito en caso de que HLT no funcione

; =============================================================================
; RELLENO Y FIRMA DE BOOT
; =============================================================================
; Rellenar hasta 510 bytes (los bootloaders deben ser exactamente de 512 bytes)
times 510 - ($ - $$) db 0

; Firma de boot sector (2 bytes finales → 0xAA55)
; Esta firma es lo que el BIOS busca para identificar un sector booteable
dw 0xAA55