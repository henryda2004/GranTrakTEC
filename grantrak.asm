[BITS 16]
[ORG 0x7C00]

jmp inicio  ; Saltamos sobre la zona de variables para empezar código

; ==================================
; SECCIÓN DE DATOS (Variables)
; ==================================
; Jugador 1
player_x        dw 50     ; Posición X inicial
player_y        dw 50     ; Posición Y inicial
player_color    db 2      ; Color verde (modo 0x12, 16c)
player_width    dw 10     ; Ancho
player_height   dw 10     ; Alto
old_x           dw 50
old_y           dw 50

; Jugador 2
player2_x       dw 100    ; Posición X inicial para el segundo jugador
player2_y       dw 100    ; Posición Y inicial para el segundo jugador
player2_color   db 4      ; Color rojo (modo 0x12, 16c)
player2_width   dw 10     ; Ancho
player2_height  dw 10     ; Alto
old2_x          dw 100
old2_y          dw 100

; ==================================
; CÓDIGO PRINCIPAL
; ==================================
inicio:
    ; Ajustar DS para que apunte al segmento 0 (somos un boot sector)
    xor ax, ax
    mov ds, ax

    ; Cambiar a modo gráfico 0x12 (640x480, 16 colores)
    mov ax, 0x12
    int 0x10

    ; -- Dibujar ambos jugadores inmediatamente --

    ; Jugador 1
    mov al, [player_color]
    mov cx, [player_x]
    mov dx, [player_y]
    mov si, [player_width]
    mov di, [player_height]
    call draw_rectangle

    ; Jugador 2
    mov al, [player2_color]
    mov cx, [player2_x]
    mov dx, [player2_y]
    mov si, [player2_width]
    mov di, [player2_height]
    call draw_rectangle

main_loop:
    ; 1) Guardar las posiciones actuales como "anteriores"
    mov ax, [player_x]
    mov [old_x], ax
    mov ax, [player_y]
    mov [old_y], ax

    mov ax, [player2_x]
    mov [old2_x], ax
    mov ax, [player2_y]
    mov [old2_y], ax

    ; 2) Leer tecla (bloquea hasta que se pulse)
    call read_key  ; AH = scancode, AL = ASCII

    ; 3) Actualizar posición según flechas (jugador 1) o WASD (jugador 2)
    call update_position

    ; 4) Borrar el rectángulo en la POSICIÓN ANTERIOR (color 0 = negro)
    ; Jugador 1
    mov al, 0
    mov cx, [old_x]
    mov dx, [old_y]
    mov si, [player_width]
    mov di, [player_height]
    call draw_rectangle

    ; Jugador 2
    mov al, 0
    mov cx, [old2_x]
    mov dx, [old2_y]
    mov si, [player2_width]
    mov di, [player2_height]
    call draw_rectangle

    ; 5) Dibujar el rectángulo en la POSICIÓN NUEVA (sus colores respectivos)
    ; Jugador 1
    mov al, [player_color]
    mov cx, [player_x]
    mov dx, [player_y]
    mov si, [player_width]
    mov di, [player_height]
    call draw_rectangle

    ; Jugador 2
    mov al, [player2_color]
    mov cx, [player2_x]
    mov dx, [player2_y]
    mov si, [player2_width]
    mov di, [player2_height]
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
;      - AH = scancode
;      - Mueve Jugador 1 con flechas, Jugador 2 con WASD
; ===============================
update_position:
    ; --- Flechas Jugador 1 ---
    cmp ah, 0x48  ; Flecha ↑
    je move_up_1
    cmp ah, 0x50  ; Flecha ↓
    je move_down_1
    cmp ah, 0x4B  ; Flecha ←
    je move_left_1
    cmp ah, 0x4D  ; Flecha →
    je move_right_1

    ; --- WASD Jugador 2 (scancodes) ---
    cmp ah, 0x11  ; W
    je move_up_2
    cmp ah, 0x1F  ; S
    je move_down_2
    cmp ah, 0x1E  ; A
    je move_left_2
    cmp ah, 0x20  ; D
    je move_right_2

    ret  ; Si no coincide, no hace nada

; === Movimientos Jugador 1 (con nuevos límites: 0..639 en X, 0..479 en Y) ===
move_up_1:
    cmp word [player_y], 1
    jle done
    sub word [player_y], 5
    jmp done

move_down_1:
    cmp word [player_y], 470  ; 480 - 10 = 470
    jge done
    add word [player_y], 5
    jmp done

move_left_1:
    cmp word [player_x], 1
    jle done
    sub word [player_x], 5
    jmp done

move_right_1:
    cmp word [player_x], 630  ; 640 - 10 = 630
    jge done
    add word [player_x], 5
    jmp done

; === Movimientos Jugador 2 ===
move_up_2:
    cmp word [player2_y], 1
    jle done
    sub word [player2_y], 5
    jmp done

move_down_2:
    cmp word [player2_y], 470
    jge done
    add word [player2_y], 5
    jmp done

move_left_2:
    cmp word [player2_x], 1
    jle done
    sub word [player2_x], 5
    jmp done

move_right_2:
    cmp word [player2_x], 630
    jge done
    add word [player2_x], 5
    jmp done

done:
    ret

; ===============================
; SUBRUTINA: DIBUJAR RECTÁNGULO
;  - CX = X inicial
;  - DX = Y inicial
;  - SI = Ancho
;  - DI = Alto
;  - AL = Color (0..15)
; ===============================
draw_rectangle:
    push cx       ; Guardar X inicial
    push dx       ; Guardar Y inicial
    push si       ; Guardar el ancho
    mov  bx, di   ; BX = altura (contador de filas)

.filas:
    mov si, [esp]      ; Recupera ancho
    mov cx, [esp + 4]  ; Recupera X inicial

.columnas:
    ; Uso de INT 0x10, función 0x0C para modo 0x12 (16 colores)
    ; BH = 0 (página), AL = color, CX = x, DX = y
    mov ah, 0x0C
    xor bh, bh       ; Página 0
    int 0x10

    inc cx
    dec si
    jnz .columnas

    inc dx
    dec bx
    jnz .filas

    pop si
    pop dx
    pop cx
    ret

; ===============================
; BOOT SECTOR (rellena hasta 512 bytes)
; ===============================
times 510 - ($ - $$) db 0
dw 0xAA55
