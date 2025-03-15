[BITS 16]
[ORG 0x7C00]

jmp inicio  ; Saltamos sobre la zona de variables para empezar código

; ==================================
; SECCIÓN DE DATOS (Variables)
; ==================================
player_x     dw 50    ; Posición X inicial
player_y     dw 50    ; Posición Y inicial
player_color db 2     ; Color verde (modo 13h)
player_width dw 10    ; Ancho
player_height dw 10   ; Alto

old_x        dw 50    ; Posición inicial para evitar borrar nada al inicio
old_y        dw 50

; ==================================
; CÓDIGO PRINCIPAL
; ==================================
inicio:
    ; Ajustar DS para que apunte al segmento correcto
    xor ax, ax
    mov ds, ax

    ; Cambiar a modo gráfico 13h (320x200, 256 colores)
    mov ax, 0x13
    int 0x10

    ; Dibujar el jugador inmediatamente después de entrar en modo gráfico
    mov al, [player_color]
    mov cx, [player_x]
    mov dx, [player_y]
    mov si, [player_width]
    mov di, [player_height]
    call draw_rectangle

main_loop:
    ; 1) Guardar la posición actual como "posición anterior"
    mov ax, [player_x]
    mov [old_x], ax
    mov ax, [player_y]
    mov [old_y], ax

    ; 2) Leer tecla (esperar a que se pulse)
    call read_key  ; AH contiene scancode, AL el ASCII

    ; 3) Actualizar la posición según la flecha
    call update_position

    ; 4) Borrar el rectángulo en la POSICIÓN ANTERIOR (negro = color 0)
    mov al, 0
    mov cx, [old_x]
    mov dx, [old_y]
    mov si, [player_width]
    mov di, [player_height]
    call draw_rectangle

    ; 5) Dibujar el rectángulo en la POSICIÓN NUEVA (verde)
    mov al, [player_color]
    mov cx, [player_x]
    mov dx, [player_y]
    mov si, [player_width]
    mov di, [player_height]
    call draw_rectangle

    jmp main_loop  ; Repetir indefinidamente

; ===============================
; SUBRUTINA: LEER TECLA (bloquea)
; ===============================
read_key:
    mov ah, 0x00   ; Función BIOS: esperar a que se pulse una tecla
    int 0x16
    ret

; ===============================
; SUBRUTINA: ACTUALIZAR POSICIÓN
;      - AH = scancode de la tecla
; ===============================
update_position:
    cmp ah, 0x48  ; Flecha ↑
    je move_up
    cmp ah, 0x50  ; Flecha ↓
    je move_down
    cmp ah, 0x4B  ; Flecha ←
    je move_left
    cmp ah, 0x4D  ; Flecha →
    je move_right
    ret           ; Si no es flecha, simplemente no hacemos nada

move_up:
    cmp word [player_y], 1   ; Límite superior
    jle done
    dec word [player_y]
    jmp done

move_down:
    cmp word [player_y], 190 ; Límite inferior (200 - 10)
    jge done
    inc word [player_y]
    jmp done

move_left:
    cmp word [player_x], 1   ; Límite izquierdo
    jle done
    dec word [player_x]
    jmp done

move_right:
    cmp word [player_x], 310 ; Límite derecho (320 - 10)
    jge done
    inc word [player_x]
done:
    ret

; ===============================
; SUBRUTINA: DIBUJAR RECTÁNGULO
;      - CX = X inicial
;      - DX = Y inicial
;      - SI = Ancho
;      - DI = Alto
;      - AL = Color
; ===============================
draw_rectangle:
    push cx       ; Guardamos X inicial
    push dx       ; Guardamos Y inicial
    push si       ; Guardamos el ancho
    mov  bx, di   ; Usamos BX para contar las filas (alto)

fila:
    mov si, [esp]     ; Recuperamos ancho
    mov cx, [esp + 4] ; Recuperamos X inicial

columna:
    mov ah, 0x0C      ; Función BIOS para plot pixel en modo 13h
    int 0x10  
    inc cx
    dec si
    jnz columna

    inc dx
    dec bx
    jnz fila

    pop si
    pop dx
    pop cx
    ret

; Rellenar hasta el tamaño de sector 512 bytes (boot)
times 510 - ($ - $$) db 0
dw 0xAA55
