[BITS 16]
[ORG 0x7C00]

jmp inicio  ; Saltamos sobre la zona de variables para empezar código

; ==================================
; SECCIÓN DE DATOS (Variables)
; ==================================
; Jugador 1
player_x        dw 50     ; Posición X inicial
player_y        dw 50     ; Posición Y inicial
player_color    db 2      ; Color verde (modo 13h)
player_width    dw 10     ; Ancho
player_height   dw 10     ; Alto
old_x           dw 50     ; Posición inicial para evitar borrar nada al inicio
old_y           dw 50

; Jugador 2
player2_x       dw 100    ; Posición X inicial para el segundo jugador
player2_y       dw 100    ; Posición Y inicial para el segundo jugador
player2_color   db 4      ; Color rojo (modo 13h)
player2_width   dw 10     ; Ancho
player2_height  dw 10     ; Alto
old2_x          dw 100
old2_y          dw 100

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

    ; Dibujar ambos jugadores inmediatamente
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
    ; 1) Guardar la posición actual como "posición anterior" (de ambos jugadores)
    mov ax, [player_x]
    mov [old_x], ax
    mov ax, [player_y]
    mov [old_y], ax

    mov ax, [player2_x]
    mov [old2_x], ax
    mov ax, [player2_y]
    mov [old2_y], ax

    ; 2) Leer tecla (esperar a que se pulse)
    call read_key  ; AH contiene scancode, AL el ASCII

    ; 3) Actualizar la posición según flechas (jugador 1) o WASD (jugador 2)
    call update_position

    ; 4) Borrar el rectángulo en la POSICIÓN ANTERIOR (color 0) de ambos jugadores
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

    ; 5) Dibujar el rectángulo en la POSICIÓN NUEVA (sus respectivos colores)
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
;      - AH = scancode de la tecla
;      - Maneja flechas (jugador 1) y WASD (jugador 2)
; ===============================
update_position:
    ; --- Flechas para Jugador 1 ---
    cmp ah, 0x48  ; Flecha ↑
    je move_up_1
    cmp ah, 0x50  ; Flecha ↓
    je move_down_1
    cmp ah, 0x4B  ; Flecha ←
    je move_left_1
    cmp ah, 0x4D  ; Flecha →
    je move_right_1

    ; --- WASD para Jugador 2 (scancodes) ---
    cmp ah, 0x11  ; W
    je move_up_2
    cmp ah, 0x1F  ; S
    je move_down_2
    cmp ah, 0x1E  ; A
    je move_left_2
    cmp ah, 0x20  ; D
    je move_right_2

    ret  ; Si no es flecha ni WASD, no hacemos nada

; === Movimientos Jugador 1 ===
move_up_1:
    cmp word [player_y], 1   ; Límite superior
    jle done
    sub word [player_y], 5
    jmp done

move_down_1:
    cmp word [player_y], 190 ; Límite inferior (200 - 10)
    jge done
    add word [player_y], 5
    jmp done

move_left_1:
    cmp word [player_x], 1   ; Límite izquierdo
    jle done
    sub word [player_x], 5
    jmp done

move_right_1:
    cmp word [player_x], 310 ; Límite derecho (320 - 10)
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
    cmp word [player2_y], 190
    jge done
    add word [player2_y], 5
    jmp done

move_left_2:
    cmp word [player2_x], 1
    jle done
    sub word [player2_x], 5
    jmp done

move_right_2:
    cmp word [player2_x], 310
    jge done
    add word [player2_x], 5
    jmp done

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
    mov si, [esp]      ; Recuperamos ancho
    mov cx, [esp + 4]  ; Recuperamos X inicial

columna:
    mov ah, 0x0C       ; Función BIOS para plot pixel en modo 13h
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

; Rellenar hasta 512 bytes
times 510 - ($ - $$) db 0
dw 0xAA55
