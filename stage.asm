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

    ; Dibujar la pista (blanca)
    call draw_track

    ; ---- Jugador 1 (VERDE) ----
    mov al, [player_color]  ; Color
    mov cx, [player_x]      ; X
    mov dx, [player_y]      ; Y
    mov si, [player_width]  ; Ancho
    mov di, [player_height] ; Alto
    call draw_rectangle

    ; ---- Jugador 2 (ROJO) ----
    mov al, [player2_color]  
    mov cx, [player2_x]      
    mov dx, [player2_y]      
    mov si, [player2_width]  
    mov di, [player2_height] 
    call draw_rectangle

    ; BOT (dibujarlo aquí para que aparezca de inmediato)
    mov al, [bot_color]
    mov cx, [bot_x]
    mov dx, [bot_y]
    mov si, [bot_width]
    mov di, [bot_height]
    call draw_rectangle


main_loop:
    call check_timer
    call display_timer 
    cmp word [time_left], 0
    je time_is_up

    ; 1) Guardar las posiciones actuales (para borrarlas luego)
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

    ; 3) Actualizar posiciones de los jugadores
    call update_position

    ; 3b) Comprobar colisión del jugador 1 (verde) con la pista blanca
    call check_collision_player1

    ; 3c) Comprobar colisión del jugador 2 (rojo) con la pista blanca
    call check_collision_player2
    
    ; 4) Borrar los rectángulos anteriores
    ; -- Jugador 1 --
    mov al, 0
    mov cx, [old_x]
    mov dx, [old_y]
    mov si, [player_width]
    mov di, [player_height]
    call draw_rectangle

    ; -- Jugador 2 --
    mov al, 0
    mov cx, [old2_x]
    mov dx, [old2_y]
    mov si, [player2_width]
    mov di, [player2_height]
    call draw_rectangle

    ; 5) Dibujar los rectángulos en la nueva posición
    ; -- Jugador 1 --
    mov al, [player_color]
    mov cx, [player_x]
    mov dx, [player_y]
    mov si, [player_width]
    mov di, [player_height]
    call draw_rectangle

    ; -- Jugador 2 --
    mov al, [player2_color]
    mov cx, [player2_x]
    mov dx, [player2_y]
    mov si, [player2_width]
    mov di, [player2_height]
    call draw_rectangle

    ; === BOT ===
    ; 1) Guardar pos anterior
    mov ax, [bot_x]
    mov [old_bot_x], ax
    mov ax, [bot_y]
    mov [old_bot_y], ax

    ; 2) Mover bot
    call move_bot

    ; 3) Borrar bot anterior
    mov al, 0
    mov cx, [old_bot_x]
    mov dx, [old_bot_y]
    mov si, [bot_width]
    mov di, [bot_height]
    call draw_rectangle

    ; 4) Dibujar bot en nueva posición
    mov al, [bot_color]
    mov cx, [bot_x]
    mov dx, [bot_y]
    mov si, [bot_width]
    mov di, [bot_height]
    call draw_rectangle



    jmp main_loop

time_is_up:
    ; Mensaje de “Fin del juego”
    ; Determinar ganador, etc.
    hlt
    jmp time_is_up

; --------------------------------------
; start_timer: lee el contador BIOS (CX:DX)
; y calcula end_time = DX + 1092 (para 60s)
; --------------------------------------
start_timer:
    mov ah, 0
    int 0x1A               ; CX:DX = ticks desde medianoche (18.2 Hz)
    mov [start_ticks], cx  ; opcional, si quieres guardarlo
    mov [start_ticks2], dx

    ; Sumar 1092 a DX para 60s
    mov ax, dx
    add ax, 1092           ; 1092 = ~18.2 * 60
    mov [end_ticks2], ax
    mov [end_ticks], cx    ; sin cambios a CX

    ; time_left = 60 (inicialmente)
    mov word [time_left], 60
    ret

; --------------------------------------
; check_timer: lee el tiempo actual y
; comprueba si ya llegamos a end_time.
;  - Si ya llegó, time_left=0
;  - Si no, calcula time_left approx
; --------------------------------------
check_timer:
    push ax
    push bx
    push cx
    push dx
    push ds       ; <--- PRESERVAR DS
    push es       ; <--- PRESERVAR ES

    mov ah, 0
    int 0x1A      ; Puede alterar DS/ES

    pop es        ; <--- RESTAURAR ES
    pop ds        ; <--- RESTAURAR DS

    ; Aquí DS vuelve a ser 0x1000
    ; (el que configuraste al inicio)
    ; ... y luego continúas con la lógica ...
    
    ; Comparar DX con end_ticks2, etc.
    cmp dx, [end_ticks2]
    jb  not_reached
    mov word [time_left], 0
    jmp short done_check

not_reached:
    mov ax, [end_ticks2]
    sub ax, dx
    mov bl, 18
    div bl
    mov [time_left], ax

done_check:
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ===============================
; SUBRUTINA: LEER TECLA
; ===============================
read_key:
    ; Save registers that might be modified
    push ds
    push es
    
    ; Read key
    mov ah, 0x00
    int 0x16
    ; Key is now in AX (AH=scancode, AL=ASCII)
    
    ; Restore registers
    pop es
    pop ds
    ret  ; Return with key in AX

; ===============================
; SUBRUTINA: MOSTRAR TIEMPO RESTANTE
; ===============================
display_timer:
    ; Save registers
    push ax
    push bx
    push cx
    push dx
    
    ; Position cursor at top right
    mov ah, 0x02    ; Set cursor position
    mov bh, 0       ; Page 0
    mov dh, 0       ; Row 0
    mov dl, 70      ; Column 70
    int 0x10
    
    ; Display time
    mov ax, [time_left]
    mov bx, 10
    mov cx, 0       ; Digit counter
    
    ; Convert to ASCII
.convert_loop:
    xor dx, dx      ; Clear high part of dividend
    div bx          ; AX / 10, quotient in AX, remainder in DX
    push dx         ; Push remainder (digit)
    inc cx          ; Increment counter
    test ax, ax     ; Check if quotient is zero
    jnz .convert_loop
    
    ; Display digits
.display_loop:
    pop dx          ; Get digit
    add dl, '0'     ; Convert to ASCII
    mov ah, 0x0E    ; Teletype output
    mov al, dl      ; Character to display
    int 0x10        ; Call BIOS
    loop .display_loop
    
    ; Display "s" for seconds
    mov ah, 0x0E
    mov al, 's'
    int 0x10
    
    ; Restore registers
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ===============================
; SUBRUTINA: ACTUALIZAR POSICIÓN
; ===============================
update_position:
    ; Jugador 1: flechas
    cmp ah, 0x48  ; Flecha ↑
    je move_up_1
    cmp ah, 0x50  ; Flecha ↓
    je move_down_1
    cmp ah, 0x4B  ; Flecha ←
    je move_left_1
    cmp ah, 0x4D  ; Flecha →
    je move_right_1

    ; Jugador 2: W, S, A, D
    cmp ah, 0x11  ; W
    je move_up_2
    cmp ah, 0x1F  ; S
    je move_down_2
    cmp ah, 0x1E  ; A
    je move_left_2
    cmp ah, 0x20  ; D
    je move_right_2

    ret

; === Jugador 1 (verde) (0..639 x, 0..479 y) ===
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

; === Jugador 2 (rojo) ===
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
; SUBRUTINA: MOVER EL BOT
; ===============================
move_bot:
    cmp byte [bot_direction], 1  ; Derecha
    je bot_move_right
    cmp byte [bot_direction], 2  ; Abajo
    je bot_move_down
    cmp byte [bot_direction], 3  ; Izquierda
    je bot_move_left
    cmp byte [bot_direction], 4  ; Arriba
    je bot_move_up
    ret

bot_move_right:
    add word [bot_x], 5
    ret

bot_move_down:
    add word [bot_y], 5
    ret

bot_move_left:
    sub word [bot_x], 5
    ret

bot_move_up:
    sub word [bot_y], 5
    ret


; ===============================
; SUBRUTINA: DIBUJAR RECTÁNGULO
; ===============================
draw_rectangle:
    ; Entra: AL=color, CX=x, DX=y, SI=ancho, DI=alto
    push cx
    push dx
    push si
    mov bx, di  ; guardamos alto en bx

.filas:
    mov si, [esp]    ; ancho en SI (cada vuelta se reinicia)
    mov cx, [esp+4]  ; X inicial

.columnas:
    mov ah, 0x0C
    xor bh, bh       ; página 0
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
    ;al: Color del rectángulo (siempre 15, que es blanco en la paleta estándar VGA)
    ;cx: Coordenada X de la esquina superior izquierda
    ;dx: Coordenada Y de la esquina superior izquierda
    ;si: Ancho del rectángulo en píxeles
    ;di: Alto del rectángulo en píxeles

    ; Tramo 1.1
    mov al, 15
    mov cx, 20
    mov dx, 10
    mov si, 600
    mov di, 5
    call draw_rectangle

    ; Tramo 1.2
    mov al, 15
    mov cx, 80
    mov dx, 70
    mov si, 480
    mov di, 5
    call draw_rectangle

    ; Tramo 2.1
    mov al, 15
    mov cx, 620
    mov dx, 10
    mov si, 5
    mov di, 180
    call draw_rectangle

    ; Tramo 2.2
    mov al, 15
    mov cx, 560
    mov dx, 70
    mov si, 5
    mov di, 50
    call draw_rectangle

    ; Tramo 3.1
    mov al, 15
    mov cx, 210
    mov dx, 190
    mov si, 415
    mov di, 5
    call draw_rectangle

    ; Tramo 3.2
    mov al, 15
    mov cx, 145
    mov dx, 120
    mov si, 420
    mov di, 5
    call draw_rectangle

    ; Tramo 4.1
    mov al, 15
    mov cx, 145
    mov dx, 120
    mov si, 5
    mov di, 150
    call draw_rectangle

    ; Tramo 4.2
    mov al, 15
    mov cx, 210
    mov dx, 190
    mov si, 5
    mov di, 20
    call draw_rectangle

    ; Tramo 5.1
    mov al, 15
    mov cx, 210
    mov dx, 210
    mov si, 415
    mov di, 5
    call draw_rectangle

    ; Tramo 5.2
    mov al, 15
    mov cx, 145
    mov dx, 270
    mov si, 400
    mov di, 5
    call draw_rectangle

    ; Tramo 6.1
    mov al, 15
    mov cx, 625
    mov dx, 210
    mov si, 5
    mov di, 160
    call draw_rectangle

    ; Tramo 6.2
    mov al, 15
    mov cx, 545
    mov dx, 270
    mov si, 5
    mov di, 20
    call draw_rectangle

    ; Tramo 7.1
    mov al, 15
    mov cx, 80
    mov dx, 290
    mov si, 470
    mov di, 5
    call draw_rectangle

    ; Tramo 7.2
    mov al, 15
    mov cx, 20
    mov dx, 370
    mov si, 610
    mov di, 5
    call draw_rectangle

    ; Tramo 8.1.1
    mov al, 15
    mov cx, 20
    mov dx, 10
    mov si, 5
    mov di, 250
    call draw_rectangle

    ; Tramo 8.1.2
    mov al, 15
    mov cx, 20
    mov dx, 260
    mov si, 5
    mov di, 110
    call draw_rectangle

    ; Tramo 8.2
    mov al, 15
    mov cx, 80
    mov dx, 70
    mov si, 5
    mov di, 225
    call draw_rectangle


    ret



; ===============================
; SUBRUTINA: COMPROBAR COLISIÓN 
; (Sólo Jugador 1 - verde)
; ===============================
; Si en el área del jugador hay al menos un píxel
; de color 15 (blanco), se asume colisión y se
; regresa al punto de partida (x=100, y=20).
; ===============================
check_collision_player1:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; Variables de apoyo en memoria
    xor ax, ax
    mov [x_off], ax       ; x_off = 0
outer_x_loop:
    xor ax, ax
    mov [y_off], ax       ; y_off = 0

outer_y_loop:
    ; Leer color del píxel en (player_x + x_off, player_y + y_off)
    mov ah, 0x0D          ; Función Read Pixel
    xor bh, bh            ; Página 0
    mov cx, [player_x]
    add cx, [x_off]
    mov dx, [player_y]
    add dx, [y_off]
    int 0x10              ; AL = color del pixel

    cmp al, 15            ; ¿Es blanco?
    je collision_detected  ; Sí -> colisión

    ; Incrementar y_off
    inc word [y_off]
    mov ax, [y_off]
    cmp ax, [player_height]

    jl outer_y_loop       ; mientras y_off < player_height

    ; Pasar a siguiente x_off
    inc word [x_off]
    mov ax, [x_off]
    cmp ax, [player_width]
    jl outer_x_loop       ; mientras x_off < player_width

    jmp no_collision

collision_detected:
    ; Restaurar posición (punto de partida)
    mov word [player_x], 100
    mov word [player_y], 20

no_collision:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ===============================
; SUBRUTINA: COMPROBAR COLISIÓN
; (Sólo Jugador 2 - rojo)
; ===============================
check_collision_player2:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; Variables de apoyo en memoria
    xor ax, ax
    mov [x_off], ax       ; x_off = 0
outer_x_loop_2:
    xor ax, ax
    mov [y_off], ax       ; y_off = 0

outer_y_loop_2:
    ; Leer color del píxel en (player2_x + x_off, player2_y + y_off)
    mov ah, 0x0D          ; Función Read Pixel
    xor bh, bh            ; Página 0
    mov cx, [player2_x]
    add cx, [x_off]
    mov dx, [player2_y]
    add dx, [y_off]
    int 0x10              ; AL = color del pixel

    cmp al, 15            ; ¿Es blanco?
    je collision_detected_2  ; Sí -> colisión

    ; Incrementar y_off
    inc word [y_off]
    mov ax, [y_off]
    cmp ax, [player2_height]
    jl outer_y_loop_2       ; mientras y_off < player2_height

    ; Pasar a siguiente x_off
    inc word [x_off]
    mov ax, [x_off]
    cmp ax, [player2_width]
    jl outer_x_loop_2       ; mientras x_off < player2_width

    jmp no_collision_2

collision_detected_2:
    ; Restaurar posición inicial del Jugador 2 (rojo)
    mov word [player2_x], 100
    mov word [player2_y], 40

no_collision_2:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ===============================
; SECCIÓN DE DATOS
; ===============================
player_x        dw 100
player_y        dw 25
player_color    db 2      ; Verde
player_width    dw 10
player_height   dw 10
old_x           dw 100
old_y           dw 20

player2_x       dw 100
player2_y       dw 40
player2_color   db 4      ; Rojo
player2_width   dw 10
player2_height  dw 10
old2_x          dw 100
old2_y          dw 40


bot_x          dw 100    ; Posición inicial en X
bot_y          dw 55     ; Posición inicial en Y
bot_color      db 1      ; Azul
bot_width      dw 10     ; Ancho del bot
bot_height     dw 10     ; Alto del bot
old_bot_x      dw 100
old_bot_y      dw 55
bot_direction  db 1  ; 1=Derecha, 2=Abajo, 3=Izquierda, 4=Arriba

; Para la rutina de colisión
x_off           dw 0
y_off           dw 0

; Observa que aquí ya no utilizamos "TIMES 510 - ($-$$) db 0" ni "dw 0xAA55"
; porque esto NO es un boot sector.

; -------------------------
; Variables para el cronómetro
; -------------------------
start_ticks dw 0      ; Guardará CX al iniciar
start_ticks2 dw 0     ; Guardará DX al iniciar
end_ticks   dw 0      ; Guardará CX cuando termine
end_ticks2  dw 0      ; Guardará DX cuando termine

time_left   dw 60     ; Segundos restantes (aprox)
