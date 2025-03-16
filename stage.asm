[bits 16]
[org 0x0000]

; -----------------------------------------------------
; Stage 2 se carga en 0x1000:0 por boot1.
; Al saltar aquí, CS=??? (pero normalmente 0x1000),
; DS=0, ES=0 (puedes ajustar según necesites).
; -----------------------------------------------------

inicio:
    ; Asegurar que DS apunta a la sección correcta
    mov ax, 0x1000
    mov ds, ax

    ; Cambiar a modo gráfico 0x12 (640x480, 16 colores)
    mov ax, 0x12
    int 0x10

    ; Dibujar la pista
    call draw_track

    ; ---- Jugador 1 ----
    mov al, [player_color]  ; Color
    mov cx, [player_x]      ; X
    mov dx, [player_y]      ; Y
    mov si, [player_width]  ; Ancho
    mov di, [player_height] ; Alto
    call draw_rectangle

    ; ---- Jugador 2 ----
    mov al, [player2_color]  
    mov cx, [player2_x]      
    mov dx, [player2_y]      
    mov si, [player2_width]  
    mov di, [player2_height] 
    call draw_rectangle


main_loop:
    ; 1) Guardar las posiciones actuales
    mov ax, [player_x]
    mov [old_x], ax
    mov ax, [player_y]
    mov [old_y], ax

    mov ax, [player2_x]
    mov [old2_x], ax
    mov ax, [player2_y]
    mov [old2_y], ax

    ; 2) Leer tecla
    call read_key  ; AH=scancode, AL=ASCII

    ; 3) Actualizar posiciones
    call update_position

    ; 4) Borrar rectángulos anteriores (color 0)
    mov al, 0
    mov cx, [old_x]
    mov dx, [old_y]
    mov si, [player_width]
    mov di, [player_height]
    call draw_rectangle

    mov al, 0
    mov cx, [old2_x]
    mov dx, [old2_y]
    mov si, [player2_width]
    mov di, [player2_height]
    call draw_rectangle

    ; 5) Dibujar nuevos
    mov al, [player_color]
    mov cx, [player_x]
    mov dx, [player_y]
    mov si, [player_width]
    mov di, [player_height]
    call draw_rectangle

    mov al, [player2_color]
    mov cx, [player2_x]
    mov dx, [player2_y]
    mov si, [player2_width]
    mov di, [player2_height]
    call draw_rectangle

    jmp main_loop


; ===============================
; SUBRUTINA: LEER TECLA
; ===============================
read_key:
    mov ah, 0x00
    int 0x16
    ret

; ===============================
; SUBRUTINA: ACTUALIZAR POSICIÓN
; ===============================
update_position:
    cmp ah, 0x48  ; Flecha ↑
    je move_up_1
    cmp ah, 0x50  ; Flecha ↓
    je move_down_1
    cmp ah, 0x4B  ; Flecha ←
    je move_left_1
    cmp ah, 0x4D  ; Flecha →
    je move_right_1

    cmp ah, 0x11  ; W
    je move_up_2
    cmp ah, 0x1F  ; S
    je move_down_2
    cmp ah, 0x1E  ; A
    je move_left_2
    cmp ah, 0x20  ; D
    je move_right_2

    ret

; === Jugador 1 (0..639 x, 0..479 y) ===
move_up_1:
    cmp word [player_y], 1
    jle done
    sub word [player_y], 5
    jmp done

move_down_1:
    cmp word [player_y], 470
    jge done
    add word [player_y], 5
    jmp done

move_left_1:
    cmp word [player_x], 1
    jle done
    sub word [player_x], 5
    jmp done

move_right_1:
    cmp word [player_x], 630
    jge done
    add word [player_x], 5
    jmp done

; === Jugador 2 ===
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
; ===============================
draw_rectangle:
    push cx
    push dx
    push si
    mov bx, di  ; alto

.filas:
    mov si, [esp]     ; ancho
    mov cx, [esp+4]   ; X inicial

.columnas:
    mov ah, 0x0C
    xor bh, bh        ; página 0
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
; SUBRUTINA: DIBUJAR LA PISTA
; ===============================
draw_track:
    ; Varios rectángulos en blanco (15)
    mov al, 15
    mov cx, 50
    mov dx, 10
    mov si, 200
    mov di, 5
    call draw_rectangle

    mov al, 15
    mov cx, 290
    mov dx, 10
    mov si, 200
    mov di, 5
    call draw_rectangle

    mov al, 15
    mov cx, 250
    mov dx, 10
    mov si, 5
    mov di, 10
    call draw_rectangle

    mov al, 15
    mov cx, 255
    mov dx, 20
    mov si, 5
    mov di, 10
    call draw_rectangle

    mov al, 15
    mov cx, 260
    mov dx, 30
    mov si, 5
    mov di, 10
    call draw_rectangle

    mov al, 15
    mov cx, 265
    mov dx, 40
    mov si, 5
    mov di, 10
    call draw_rectangle

    mov al, 15
    mov cx, 270
    mov dx, 50
    mov si, 5
    mov di, 10
    call draw_rectangle

    ret

; ===============================
; SECCIÓN DE DATOS
; ===============================
player_x        dw 100
player_y        dw 50
player_color    db 2
player_width    dw 10
player_height   dw 10
old_x           dw 100
old_y           dw 50

player2_x       dw 100
player2_y       dw 70
player2_color   db 4
player2_width   dw 10
player2_height  dw 10
old2_x          dw 100
old2_y          dw 50

; NO SE PONE TIMES 510... NI dw 0xAA55
; Porque NO es un boot sector
