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

    ; 1) Inicializamos la semilla
    call init_random_seed

    ; 2) Asignamos velocidades aleatorias a cada bot en el rango 5..20
    mov bx, 5
    mov cx, 15
    call random_range
    mov [bot_speed], ax

    mov bx, 5
    mov cx, 15
    call random_range
    mov [bot2_speed], ax

    mov bx, 5
    mov cx, 15
    call random_range
    mov [bot3_speed], ax
    ; Inicializar temporizador (obtener ticks iniciales)
    mov ah, 0x00
    int 0x1A
    mov [time_start], dx  ; Guardar ticks iniciales (CX:DX)
    
    ; Dibujar elementos iniciales
    call draw_track
    call update_timer  ; Mostrar tiempo inicial
    call update_lap_counter  ; Mostrar contador inicial

    ; 7) Verificar si completó una vuelta
    call check_player1_lap
    
    call check_player2_lap
    call update_lap_counter_p2

    call check_bot1_lap
    call update_lap_counter_bot1

    call check_bot2_lap
    call update_lap_counter_bot2

    call check_bot3_lap
    call update_lap_counter_bot3

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

    ; BOT 2 
    mov al, [bot2_color]
    mov cx, [bot2_x]
    mov dx, [bot2_y]
    mov si, [bot2_width]
    mov di, [bot2_height]
    call draw_rectangle

    ; BOT 3
    mov al, [bot3_color]
    mov cx, [bot3_x]
    mov dx, [bot3_y]
    mov si, [bot3_width]
    mov di, [bot3_height]
    call draw_rectangle


main_loop:
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

    ; === BOT 2 ===
    ; 1) Guardar pos anterior
    mov ax, [bot2_x]
    mov [old_bot2_x], ax
    mov ax, [bot2_y]
    mov [old_bot2_y], ax

    ; 2) Mover bot 2
    call move_bot2

    ; 3) Borrar bot anterior
    mov al, 0
    mov cx, [old_bot2_x]
    mov dx, [old_bot2_y]
    mov si, [bot2_width]
    mov di, [bot2_height]
    call draw_rectangle

    ; 4) Dibujar bot en nueva posición
    mov al, [bot2_color]
    mov cx, [bot2_x]
    mov dx, [bot2_y]
    mov si, [bot2_width]
    mov di, [bot2_height]
    call draw_rectangle

    ; === BOT 3 ===
    ; 1) Guardar pos anterior
    mov ax, [bot3_x]
    mov [old_bot3_x], ax
    mov ax, [bot3_y]
    mov [old_bot3_y], ax

    ; 2) Mover bot 3
    call move_bot3

    ; 3) Borrar bot anterior
    mov al, 0
    mov cx, [old_bot3_x]
    mov dx, [old_bot3_y]
    mov si, [bot3_width]
    mov di, [bot3_height]
    call draw_rectangle

    ; 4) Dibujar bot en nueva posición
    mov al, [bot3_color]
    mov cx, [bot3_x]
    mov dx, [bot3_y]
    mov si, [bot3_width]
    mov di, [bot3_height]
    call draw_rectangle

    ; -- Aquí invocas la comprobación de vuelta --
    call check_player1_lap
    call update_lap_counter
    call check_player2_lap
    call update_lap_counter_p2

    ; Verificar vueltas de los bots
    call check_bot1_lap
    call update_lap_counter_bot1

    call check_bot2_lap
    call update_lap_counter_bot2

    call check_bot3_lap
    call update_lap_counter_bot3

    ; 6) Actualizar temporizador
    call update_timer

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
    sub word [player_y], 10
    jmp done

move_down_1:
    cmp word [player_y], 470
    jge done
    add word [player_y], 10
    jmp done

move_left_1:
    cmp word [player_x], 1
    jle done
    sub word [player_x], 10
    jmp done

move_right_1:
    cmp word [player_x], 630
    jge done
    add word [player_x], 10
    jmp done

; === Jugador 2 (rojo) ===
move_up_2:
    cmp word [player2_y], 1
    jle done
    sub word [player2_y], 10
    jmp done

move_down_2:
    cmp word [player2_y], 470
    jge done
    add word [player2_y], 10
    jmp done

move_left_2:
    cmp word [player2_x], 1
    jle done
    sub word [player2_x], 10
    jmp done

move_right_2:
    cmp word [player2_x], 630
    jge done
    add word [player2_x], 10
    jmp done

done:
    ret

; ===============================
; SUBRUTINA: MOVER EL BOT
; ===============================
move_bot:
    ; Primero comprobar si ha llegado a un punto de cambio
    call check_bot_waypoints
    
    ; Luego realizar el movimiento según la dirección actual
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
    mov cx, [bot_speed]
    add word [bot_x], cx
    ret

bot_move_down:
    mov cx, [bot_speed]
    add word [bot_y], cx
    ret

bot_move_left:
    mov cx, [bot_speed]
    sub word [bot_x], cx
    ret

bot_move_up:
    mov cx, [bot_speed]
    sub word [bot_y], cx
    ret

; ===============================
; SUBRUTINA: MOVER EL BOT 2
; ===============================
move_bot2:
    ; Comprobar si ha llegado a un punto de cambio
    call check_bot2_waypoints
    
    ; Realizar el movimiento según la dirección actual
    cmp byte [bot2_direction], 1  ; Derecha
    je bot2_move_right
    cmp byte [bot2_direction], 2  ; Abajo
    je bot2_move_down
    cmp byte [bot2_direction], 3  ; Izquierda
    je bot2_move_left
    cmp byte [bot2_direction], 4  ; Arriba
    je bot2_move_up
    ret

bot2_move_right:
    mov cx, [bot2_speed]
    add word [bot2_x], cx
    ret

bot2_move_down:
    mov cx, [bot2_speed]
    add word [bot2_y], cx
    ret

bot2_move_left:
    mov cx, [bot2_speed]
    sub word [bot2_x], cx
    ret

bot2_move_up:
    mov cx, [bot2_speed]
    sub word [bot2_y], cx
    ret
    
; ===============================
; SUBRUTINA: MOVER EL BOT 3
; ===============================
move_bot3:
    ; Comprobar si ha llegado a un punto de cambio
    call check_bot3_waypoints
    
    ; Realizar el movimiento según la dirección actual
    cmp byte [bot3_direction], 1  ; Derecha
    je bot3_move_right
    cmp byte [bot3_direction], 2  ; Abajo
    je bot3_move_down
    cmp byte [bot3_direction], 3  ; Izquierda
    je bot3_move_left
    cmp byte [bot3_direction], 4  ; Arriba
    je bot3_move_up
    ret

bot3_move_right:
    mov cx, [bot3_speed]
    add word [bot3_x], cx
    ret

bot3_move_down:
    mov cx, [bot3_speed]
    add word [bot3_y], cx
    ret

bot3_move_left:
    mov cx, [bot3_speed]
    sub word [bot3_x], cx
    ret

bot3_move_up:
    mov cx, [bot3_speed]
    sub word [bot3_y], cx
    ret
; ===============================
; SUBRUTINA: VERIFICAR PUNTOS DE CAMBIO DEL BOT
; ===============================
check_bot_waypoints:
    ; Comprueba si el bot ha llegado al punto de cambio 1 (USANDO RANGOS)
    mov ax, [bot_x]
    sub ax, [waypoint1_x]     ; AX = bot_x - waypoint1_x
    jns check_wp1_positive    ; Si es positivo, seguir
    neg ax                    ; Si es negativo, hacerlo positivo
check_wp1_positive:
    cmp ax, [waypoint_range]  ; Comparar con el rango aceptable
    ja check_waypoint2        ; Si está fuera del rango, comprobar el siguiente waypoint
    
    mov ax, [bot_y]
    sub ax, [waypoint1_y]
    jns check_wp1_y_positive
    neg ax
check_wp1_y_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint2
    
    ; Si llegó aquí, el bot está en el rango del waypoint1
    mov al, [waypoint1_dir]
    mov [bot_direction], al
    jmp end_check_waypoints
    
check_waypoint2:
    ; Comprueba si el bot ha llegado al punto de cambio 2 (USANDO RANGOS)
    mov ax, [bot_x]
    sub ax, [waypoint2_x]
    jns check_wp2_positive
    neg ax
check_wp2_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint3
    
    mov ax, [bot_y]
    sub ax, [waypoint2_y]
    jns check_wp2_y_positive
    neg ax
check_wp2_y_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint3
    
    ; Si llegó aquí, el bot está en el rango del waypoint2
    mov al, [waypoint2_dir]
    mov [bot_direction], al
    jmp end_check_waypoints
    
check_waypoint3:
    ; Comprueba si el bot ha llegado al punto de cambio 3 (USANDO RANGOS)
    mov ax, [bot_x]
    sub ax, [waypoint3_x]
    jns check_wp3_positive
    neg ax
check_wp3_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint4
    
    mov ax, [bot_y]
    sub ax, [waypoint3_y]
    jns check_wp3_y_positive
    neg ax
check_wp3_y_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint4
    
    ; Si llegó aquí, el bot está en el rango del waypoint3
    mov al, [waypoint3_dir]
    mov [bot_direction], al
    jmp end_check_waypoints

check_waypoint4:
    ; Comprueba si el bot ha llegado al punto de cambio 4 (USANDO RANGOS)
    mov ax, [bot_x]
    sub ax, [waypoint4_x]
    jns check_wp4_positive
    neg ax
check_wp4_positive:
    cmp ax, [waypoint_range]
    ja end_check_waypoints
    
    mov ax, [bot_y]
    sub ax, [waypoint4_y]
    jns check_wp4_y_positive
    neg ax
check_wp4_y_positive:
    cmp ax, [waypoint_range]
    ja end_check_waypoints
    
    ; Si llegó aquí, el bot está en el rango del waypoint4
    mov al, [waypoint4_dir]
    mov [bot_direction], al
    
end_check_waypoints:
    ret


; ===============================
; SUBRUTINA: VERIFICAR PUNTOS DE CAMBIO DEL BOT 2
; ===============================
check_bot2_waypoints:
    ; Bot 2 usa los mismos waypoints que el bot 1
    
    ; Comprueba si el bot 2 ha llegado al punto de cambio 1
    mov ax, [bot2_x]
    sub ax, [waypoint1_x]
    jns check_wp1_bot2_positive
    neg ax
check_wp1_bot2_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint2_bot2
    
    mov ax, [bot2_y]
    sub ax, [waypoint1_y]
    jns check_wp1_y_bot2_positive
    neg ax
check_wp1_y_bot2_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint2_bot2
    
    ; Bot 2 está en el rango del waypoint1
    mov al, [waypoint1_dir]
    mov [bot2_direction], al
    jmp end_check_waypoints_bot2
    
check_waypoint2_bot2:
    ; Comprueba waypoint 2
    mov ax, [bot2_x]
    sub ax, [waypoint2_x]
    jns check_wp2_bot2_positive
    neg ax
check_wp2_bot2_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint3_bot2
    
    mov ax, [bot2_y]
    sub ax, [waypoint2_y]
    jns check_wp2_y_bot2_positive
    neg ax
check_wp2_y_bot2_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint3_bot2
    
    ; Bot 2 está en el rango del waypoint2
    mov al, [waypoint2_dir]
    mov [bot2_direction], al
    jmp end_check_waypoints_bot2
    
check_waypoint3_bot2:
    ; Comprueba waypoint 3
    mov ax, [bot2_x]
    sub ax, [waypoint3_x]
    jns check_wp3_bot2_positive
    neg ax
check_wp3_bot2_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint4_bot2
    
    mov ax, [bot2_y]
    sub ax, [waypoint3_y]
    jns check_wp3_y_bot2_positive
    neg ax
check_wp3_y_bot2_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint4_bot2
    
    ; Bot 2 está en el rango del waypoint3
    mov al, [waypoint3_dir]
    mov [bot2_direction], al
    jmp end_check_waypoints_bot2

check_waypoint4_bot2:
    ; Comprueba waypoint 4
    mov ax, [bot2_x]
    sub ax, [waypoint4_x]
    jns check_wp4_bot2_positive
    neg ax
check_wp4_bot2_positive:
    cmp ax, [waypoint_range]
    ja end_check_waypoints_bot2
    
    mov ax, [bot2_y]
    sub ax, [waypoint4_y]
    jns check_wp4_y_bot2_positive
    neg ax
check_wp4_y_bot2_positive:
    cmp ax, [waypoint_range]
    ja end_check_waypoints_bot2
    
    ; Bot 2 está en el rango del waypoint4
    mov al, [waypoint4_dir]
    mov [bot2_direction], al
    
end_check_waypoints_bot2:
    ret

; ===============================
; SUBRUTINA: VERIFICAR PUNTOS DE CAMBIO DEL BOT 3
; ===============================
check_bot3_waypoints:
    ; Bot 3 usa los mismos waypoints que los otros bots
    
    ; Comprueba si el bot 3 ha llegado al punto de cambio 1
    mov ax, [bot3_x]
    sub ax, [waypoint1_x]
    jns check_wp1_bot3_positive
    neg ax
check_wp1_bot3_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint2_bot3
    
    mov ax, [bot3_y]
    sub ax, [waypoint1_y]
    jns check_wp1_y_bot3_positive
    neg ax
check_wp1_y_bot3_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint2_bot3
    
    ; Bot 3 está en el rango del waypoint1
    mov al, [waypoint1_dir]
    mov [bot3_direction], al
    jmp end_check_waypoints_bot3
    
check_waypoint2_bot3:
    ; Comprueba waypoint 2
    mov ax, [bot3_x]
    sub ax, [waypoint2_x]
    jns check_wp2_bot3_positive
    neg ax
check_wp2_bot3_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint3_bot3
    
    mov ax, [bot3_y]
    sub ax, [waypoint2_y]
    jns check_wp2_y_bot3_positive
    neg ax
check_wp2_y_bot3_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint3_bot3
    
    ; Bot 3 está en el rango del waypoint2
    mov al, [waypoint2_dir]
    mov [bot3_direction], al
    jmp end_check_waypoints_bot3
    
check_waypoint3_bot3:
    ; Comprueba waypoint 3
    mov ax, [bot3_x]
    sub ax, [waypoint3_x]
    jns check_wp3_bot3_positive
    neg ax
check_wp3_bot3_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint4_bot3
    
    mov ax, [bot3_y]
    sub ax, [waypoint3_y]
    jns check_wp3_y_bot3_positive
    neg ax
check_wp3_y_bot3_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint4_bot3
    
    ; Bot 3 está en el rango del waypoint3
    mov al, [waypoint3_dir]
    mov [bot3_direction], al
    jmp end_check_waypoints_bot3

check_waypoint4_bot3:
    ; Comprueba waypoint 4
    mov ax, [bot3_x]
    sub ax, [waypoint4_x]
    jns check_wp4_bot3_positive
    neg ax
check_wp4_bot3_positive:
    cmp ax, [waypoint_range]
    ja end_check_waypoints_bot3
    
    mov ax, [bot3_y]
    sub ax, [waypoint4_y]
    jns check_wp4_y_bot3_positive
    neg ax
check_wp4_y_bot3_positive:
    cmp ax, [waypoint_range]
    ja end_check_waypoints_bot3
    
    ; Bot 3 está en el rango del waypoint4
    mov al, [waypoint4_dir]
    mov [bot3_direction], al
    
end_check_waypoints_bot3:
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
; SUBRUTINA: ACTUALIZAR TEMPORIZADOR
; ===============================
update_timer:
    pusha
    ; Obtener ticks actuales
    mov ah, 0x00
    int 0x1A
    mov [time_current], dx

    ; Calcular segundos transcurridos (18.2 ticks/segundo)
    mov ax, [time_current]
    sub ax, [time_start]
    xor dx, dx
    mov cx, 18
    div cx          ; AX = segundos aproximados

    ; Calcular segundos restantes
    mov bx, 60
    sub bx, ax
    mov [time_seconds], bx

    cmp word [time_seconds], 0
    jne .continue_game
    jmp game_over

    .continue_game:


    ; Actualizar cadena del tiempo
    mov di, time_str + 6  ; Posición del número en "Time: 60"
    mov ax, [time_seconds]
    call word_to_ascii

    ; Dibujar el tiempo en (0,0)
    mov ah, 0x13        ; Función BIOS: Escribir cadena
    mov al, 0x01        ; Modo de escritura (actualizar posición)
    mov bh, 0x00        ; Página 0
    mov bl, 0x0F        ; Color blanco sobre negro
    mov cx, 8           ; Longitud de la cadena
    mov dh, 17           ; Fila 0
    mov dl, 3           ; Columna 0
    mov bp, time_str
    int 0x10

    popa
    ret

game_over:
    ; Cambiar a modo texto 80x25 (16 colores)
    mov ax, 0x0003
    int 0x10
    
    call determine_winner
    call show_winner_message
.halt:
    jmp .halt  ; Bucle infinito para congelar el juego


; ===============================
; SUBRUTINA: CONVERTIR WORD A ASCII
; Entrada: AX = número, DI = destino
; ===============================
word_to_ascii:
    pusha
    mov cx, 10
    xor dx, dx
    div cx          ; AX = cociente, DX = residuo
    add dl, '0'     ; Convertir residuo a ASCII
    mov [di+1], dl
    xor dx, dx
    div cx
    add dl, '0'
    mov [di], dl
    popa
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
    mov dx, 15
    mov si, 600
    mov di, 5
    call draw_rectangle

    ; Tramo 1.2
    mov al, 15
    mov cx, 80
    mov dx, 75
    mov si, 480
    mov di, 5
    call draw_rectangle

    ; Tramo 2.1
    mov al, 15
    mov cx, 620
    mov dx, 15
    mov si, 5
    mov di, 250
    call draw_rectangle

    ; Tramo 2.2
    mov al, 15
    mov cx, 555
    mov dx, 80
    mov si, 5
    mov di, 125
    call draw_rectangle

    ; Tramo 3.1
    mov al, 15
    mov cx, 25
    mov dx, 265
    mov si, 600
    mov di, 5
    call draw_rectangle

    ; Tramo 3.2
    mov al, 15
    mov cx, 80
    mov dx, 200
    mov si, 480
    mov di, 5
    call draw_rectangle

    ; Tramo 4.1
    mov al, 15
    mov cx, 20
    mov dx, 15
    mov si, 5
    mov di, 255
    call draw_rectangle

    ; Tramo 4.2
    mov al, 15
    mov cx, 80
    mov dx, 75
    mov si, 5
    mov di, 125
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
    mov word [player_x], 110
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
    mov word [player2_x], 110
    mov word [player2_y], 40

no_collision_2:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; ========================================
; SUBRUTINA: INIT_RANDOM_SEED
;  - Inicializa la semilla con los ticks del BIOS
; ========================================
init_random_seed:
    push ax
    push dx
    
    mov ah, 0x00   ; Función 0 de int 1Ah -> get system time
    int 0x1A
    ; DX contiene los ticks (parte baja)
    mov [random_seed], dx
    
    ; Asegurarse que la semilla nunca sea 0
    cmp word [random_seed], 0
    jne .seed_ok
    mov word [random_seed], 1234  ; Valor alternativo si es 0
    
.seed_ok:
    pop dx
    pop ax
    ret


; ========================================
; SUBRUTINA: RANDOM_LCG
;  - Generador pseudoaleatorio (lineal congruencial)
;  - Devuelve en AX el nuevo valor pseudoaleatorio
;    (y lo deja guardado en random_seed).
; ========================================
random_lcg:
    ; Formula típica: seed = (seed * A + C) mod 65536
    push bx
    push cx
    push dx
    
    ; Asegurarse que la semilla nunca sea 0
    cmp word [random_seed], 0
    jne .seed_not_zero
    mov word [random_seed], 1234  ; Valor alternativo si es 0
    
.seed_not_zero:
    mov ax, [random_seed]
    mov cx, 25173         ; Valor A: 25173 (0x6253)
    mul cx                ; DX:AX = AX * CX
    add ax, 13849         ; Valor C: 13849 (0x3619)
    ; (mod 65536) es automático en 16 bits
    mov [random_seed], ax
    
    pop dx
    pop cx
    pop bx
    ret


; ========================================
; SUBRUTINA: RANDOM_RANGE
;  - Genera un número en el rango [BX, CX]
;  - Devuelve en AX el número.
;  - Ejemplo de uso:
;       mov bx, 5   ; Mínimo
;       mov cx, 20  ; Máximo
;       call random_range
;       ; AX = valor en [5..20]
; ========================================
random_range:
    push dx
    push bx
    push cx

    ; 1) Llamamos a random_lcg para obtener un pseudoaleatorio en AX
    call random_lcg

    ; 2) Guardar los valores min/max
    mov dx, cx      ; DX = max
    sub dx, bx      ; DX = max - min
    inc dx          ; DX = max - min + 1 (rango)

    ; Si el rango es 0, devolver el mínimo
    cmp dx, 0
    jne .continue
    mov ax, bx      ; Devolver mínimo
    jmp .done

.continue:
    ; 3) AX = AX mod rango
    xor cx, cx      ; Limpiar CX para la división
    push dx         ; Guardar el rango
    xor dx, dx      ; Limpiar DX para la división
    
    pop cx          ; CX = rango
    div cx          ; AX = AX / CX, DX = AX mod CX
    
    mov ax, dx      ; AX = AX mod rango

    ; 4) Sumamos el mínimo
    add ax, bx      ; AX = (AX mod rango) + min

.done:
    pop cx
    pop bx
    pop dx
    ret


; ===============================
; SUBRUTINA: ACTUALIZAR CONTADOR DE VUELTAS
; ===============================
update_lap_counter:
    pusha
    
    ; Actualizar la cadena con el número actual de vueltas
    mov di, player1_lap_str + 9  ; Posición del número en "P1 Laps: 00"
    mov ax, [player1_laps]
    call word_to_ascii
    
    ; Dibujar el contador en (0,1) - justo debajo del tiempo
    mov ah, 0x13        ; Función BIOS: Escribir cadena
    mov al, 0x01        ; Modo de escritura (actualizar posición)
    mov bh, 0x00        ; Página 0
    mov bl, 0x0F        ; Color blanco sobre negro
    mov cx, 11          ; Longitud de la cadena
    mov dh, 17           ; Fila 1 (debajo del tiempo)
    mov dl, 13           ; Columna 0
    mov bp, player1_lap_str
    int 0x10
    
    popa
    ret


; ===============================
; SUBRUTINA: VERIFICAR VUELTAS DEL JUGADOR 1
; ===============================
; Add a second checkpoint on the opposite side of the track
; Modify the check_player1_lap routine to implement a two-checkpoint system

check_player1_lap:
    pusha
    
    ;-----------------------------------------
    ; 1) Revisar si el jugador está en checkpoint1
    ;-----------------------------------------
    mov ax, [player_x]
    cmp ax, [checkpoint_x1]
    jl .check_checkpoint2    ; si x < checkpoint_x1, no está en checkpoint1
    cmp ax, [checkpoint_x2]
    jg .check_checkpoint2    ; si x > checkpoint_x2, no está en checkpoint1
    
    mov ax, [player_y]
    cmp ax, [checkpoint_y1]
    jl .check_checkpoint2
    cmp ax, [checkpoint_y2]
    jg .check_checkpoint2

    ; => El jugador SÍ está dentro de las coords del Checkpoint1
    ; Si ya había pasado el checkpoint2, completamos la vuelta
    cmp byte [checkpoint2_passed], 1
    jne .set_in_checkpoint      ; si no pasó checkpoint2, no contamos vuelta

    ; aquí es que checkpoint2_passed = 1
    inc word [player1_laps]     ; sumar 1 vuelta
    mov byte [checkpoint2_passed], 0  ; reset para la próxima vuelta

.set_in_checkpoint:
    mov byte [in_checkpoint], 1  ; marcar que estás en checkpoint1
    jmp .done

;-----------------------------------------
; 2) Revisar si el jugador está en checkpoint2
;-----------------------------------------
.check_checkpoint2:
    mov ax, [player_x]
    cmp ax, [checkpoint2_x1]
    jl .not_in_checkpoint
    cmp ax, [checkpoint2_x2]
    jg .not_in_checkpoint

    mov ax, [player_y]
    cmp ax, [checkpoint2_y1]
    jl .not_in_checkpoint
    cmp ax, [checkpoint2_y2]
    jg .not_in_checkpoint

    ; => El jugador SÍ está dentro de las coords del Checkpoint2
    cmp byte [in_checkpoint], 1
    jne .done                  ; si no venías del checkpoint1, no hacemos nada

    ; aquí es que in_checkpoint=1 => venías del checkpoint1
    mov byte [checkpoint2_passed], 1
    mov byte [in_checkpoint], 0  ; sales de checkpoint1

    jmp .done

.not_in_checkpoint:
    ; El jugador no está en ningún checkpoint, no hacemos nada especial

.done:
    popa
    ret

check_player2_lap:
    pusha
    
    ;-----------------------------------------
    ; 1) Revisar si el jugador está en checkpoint1
    ;-----------------------------------------
    mov ax, [player2_x]
    cmp ax, [checkpoint_x1]
    jl .check_checkpoint2    ; Si x < checkpoint_x1, no está en checkpoint1
    cmp ax, [checkpoint_x2]
    jg .check_checkpoint2    ; Si x > checkpoint_x2, no está en checkpoint1
    
    mov ax, [player2_y]
    cmp ax, [checkpoint_y1]
    jl .check_checkpoint2
    cmp ax, [checkpoint_y2]
    jg .check_checkpoint2

    ; El jugador 2 SÍ está en el Checkpoint1
    cmp byte [checkpoint2_passed_p2], 1
    jne .set_in_checkpoint      ; Si no pasó checkpoint2, no contamos vuelta

    ; Aquí se verifica que pasó el Checkpoint2, sumar vuelta
    inc word [player2_laps]
    mov byte [checkpoint2_passed_p2], 0  ; Reset para la próxima vuelta

.set_in_checkpoint:
    mov byte [in_checkpoint_p2], 1
    jmp .done

;-----------------------------------------
; 2) Revisar si el jugador está en checkpoint2
;-----------------------------------------
.check_checkpoint2:
    mov ax, [player2_x]
    cmp ax, [checkpoint2_x1]
    jl .not_in_checkpoint
    cmp ax, [checkpoint2_x2]
    jg .not_in_checkpoint

    mov ax, [player2_y]
    cmp ax, [checkpoint2_y1]
    jl .not_in_checkpoint
    cmp ax, [checkpoint2_y2]
    jg .not_in_checkpoint

    ; El jugador 2 SÍ está en el Checkpoint2
    cmp byte [in_checkpoint_p2], 1
    jne .done

    ; Confirmar paso por Checkpoint2
    mov byte [checkpoint2_passed_p2], 1
    mov byte [in_checkpoint_p2], 0

    jmp .done

.not_in_checkpoint:
    ; No está en ningún checkpoint
.done:
    popa
    ret
update_lap_counter_p2:
    pusha
    
    ; Actualizar la cadena con el número actual de vueltas
    mov di, player2_lap_str + 9  ; Posición del número en "P2 Laps: 00"
    mov ax, [player2_laps]
    call word_to_ascii
    
    ; Dibujar el contador en (0,2) - Justo debajo del contador del Player 1
    mov ah, 0x13        ; Función BIOS: Escribir cadena
    mov al, 0x01        ; Modo de escritura (actualizar posición)
    mov bh, 0x00        ; Página 0
    mov bl, 0x0F        ; Color blanco sobre negro
    mov cx, 11          ; Longitud de la cadena
    mov dh, 17           ; Fila 2
    mov dl, 26           ; Columna 0
    mov bp, player2_lap_str
    int 0x10
    
    popa
    ret

check_bot1_lap:
    pusha
    
    ;-----------------------------------------
    ; 1) Revisar si el bot está en checkpoint1
    ;-----------------------------------------
    mov ax, [bot_x]
    cmp ax, [checkpoint_x1]
    jl .check_checkpoint2
    cmp ax, [checkpoint_x2]
    jg .check_checkpoint2
    
    mov ax, [bot_y]
    cmp ax, [checkpoint_y1]
    jl .check_checkpoint2
    cmp ax, [checkpoint_y2]
    jg .check_checkpoint2

    ; Si pasó checkpoint2, sumar vuelta
    cmp byte [checkpoint2_passed_bot1], 1
    jne .set_in_checkpoint

    inc word [bot1_laps]
    mov byte [checkpoint2_passed_bot1], 0

.set_in_checkpoint:
    mov byte [in_checkpoint_bot1], 1
    jmp .done

;-----------------------------------------
; 2) Revisar si el bot está en checkpoint2
;-----------------------------------------
.check_checkpoint2:
    mov ax, [bot_x]
    cmp ax, [checkpoint2_x1]
    jl .not_in_checkpoint
    cmp ax, [checkpoint2_x2]
    jg .not_in_checkpoint

    mov ax, [bot_y]
    cmp ax, [checkpoint2_y1]
    jl .not_in_checkpoint
    cmp ax, [checkpoint2_y2]
    jg .not_in_checkpoint

    ; Si estaba en checkpoint1, marcar checkpoint2 como pasado
    cmp byte [in_checkpoint_bot1], 1
    jne .done

    mov byte [checkpoint2_passed_bot1], 1
    mov byte [in_checkpoint_bot1], 0

.not_in_checkpoint:
.done:
    popa
    ret
update_lap_counter_bot1:
    pusha
    
    ; Actualizar la cadena con el número actual de vueltas
    mov di, bot1_lap_str + 9  ; Posición del número en "Bot1 Laps: 00"
    mov ax, [bot1_laps]
    call word_to_ascii
    
    ; Dibujar en pantalla (fila 3 para bot 1)
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0x00
    mov bl, 0x0F
    mov cx, 11
    mov dh, 17
    mov dl, 39
    mov bp, bot1_lap_str
    int 0x10
    
    popa
    ret

check_bot2_lap:
    pusha
    
    ;-----------------------------------------
    ; 1) Revisar si el bot está en checkpoint1
    ;-----------------------------------------
    mov ax, [bot2_x]
    cmp ax, [checkpoint_x1]
    jl .check_checkpoint2
    cmp ax, [checkpoint_x2]
    jg .check_checkpoint2
    
    mov ax, [bot2_y]
    cmp ax, [checkpoint_y1]
    jl .check_checkpoint2
    cmp ax, [checkpoint_y2]
    jg .check_checkpoint2

    ; Si pasó checkpoint2, sumar vuelta
    cmp byte [checkpoint2_passed_bot2], 1
    jne .set_in_checkpoint

    inc word [bot2_laps]
    mov byte [checkpoint2_passed_bot2], 0

.set_in_checkpoint:
    mov byte [in_checkpoint_bot2], 1
    jmp .done

;-----------------------------------------
; 2) Revisar si el bot está en checkpoint2
;-----------------------------------------
.check_checkpoint2:
    mov ax, [bot2_x]
    cmp ax, [checkpoint2_x1]
    jl .not_in_checkpoint
    cmp ax, [checkpoint2_x2]
    jg .not_in_checkpoint

    mov ax, [bot2_y]
    cmp ax, [checkpoint2_y1]
    jl .not_in_checkpoint
    cmp ax, [checkpoint2_y2]
    jg .not_in_checkpoint

    ; Si estaba en checkpoint1, marcar checkpoint2 como pasado
    cmp byte [in_checkpoint_bot2], 1
    jne .done

    mov byte [checkpoint2_passed_bot2], 1
    mov byte [in_checkpoint_bot2], 0

.not_in_checkpoint:
.done:
    popa
    ret
update_lap_counter_bot2:
    pusha
    
    ; Actualizar la cadena con el número actual de vueltas
    mov di, bot2_lap_str + 9  ; Posición del número en "Bot1 Laps: 00"
    mov ax, [bot2_laps]
    call word_to_ascii
    
    ; Dibujar en pantalla (fila 3 para bot 1)
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0x00
    mov bl, 0x0F
    mov cx, 11
    mov dh, 17
    mov dl, 52
    mov bp, bot2_lap_str
    int 0x10
    
    popa
    ret


check_bot3_lap:
    pusha
    
    ;-----------------------------------------
    ; 1) Revisar si el bot está en checkpoint1
    ;-----------------------------------------
    mov ax, [bot3_x]
    cmp ax, [checkpoint_x1]
    jl .check_checkpoint2
    cmp ax, [checkpoint_x2]
    jg .check_checkpoint2
    
    mov ax, [bot3_y]
    cmp ax, [checkpoint_y1]
    jl .check_checkpoint2
    cmp ax, [checkpoint_y2]
    jg .check_checkpoint2

    ; Si pasó checkpoint2, sumar vuelta
    cmp byte [checkpoint2_passed_bot3], 1
    jne .set_in_checkpoint

    inc word [bot3_laps]
    mov byte [checkpoint2_passed_bot3], 0

.set_in_checkpoint:
    mov byte [in_checkpoint_bot3], 1
    jmp .done

;-----------------------------------------
; 2) Revisar si el bot está en checkpoint2
;-----------------------------------------
.check_checkpoint2:
    mov ax, [bot3_x]
    cmp ax, [checkpoint2_x1]
    jl .not_in_checkpoint
    cmp ax, [checkpoint2_x2]
    jg .not_in_checkpoint

    mov ax, [bot3_y]
    cmp ax, [checkpoint2_y1]
    jl .not_in_checkpoint
    cmp ax, [checkpoint2_y2]
    jg .not_in_checkpoint

    ; Si estaba en checkpoint1, marcar checkpoint2 como pasado
    cmp byte [in_checkpoint_bot3], 1
    jne .done

    mov byte [checkpoint2_passed_bot3], 1
    mov byte [in_checkpoint_bot3], 0

.not_in_checkpoint:
.done:
    popa
    ret
update_lap_counter_bot3:
    pusha
    
    ; Actualizar la cadena con el número actual de vueltas
    mov di, bot3_lap_str + 9  ; Posición del número en "Bot1 Laps: 00"
    mov ax, [bot3_laps]
    call word_to_ascii
    
    ; Dibujar en pantalla (fila 3 para bot 1)
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0x00
    mov bl, 0x0F
    mov cx, 11
    mov dh, 17
    mov dl, 65
    mov bp, bot3_lap_str
    int 0x10
    
    popa
    ret


determine_winner:
    pusha

    ; Find the maximum lap count first
    mov ax, [player1_laps]
    mov bx, [player2_laps]
    cmp bx, ax
    jle .check_b1_max
    mov ax, bx
    
.check_b1_max:
    mov bx, [bot1_laps]
    cmp bx, ax
    jle .check_b2_max
    mov ax, bx
    
.check_b2_max:
    mov bx, [bot2_laps]
    cmp bx, ax
    jle .check_b3_max
    mov ax, bx
    
.check_b3_max:
    mov bx, [bot3_laps]
    cmp bx, ax
    jle .set_max
    mov ax, bx

.set_max:
    ; Now ax has the maximum lap count
    mov [max_laps], ax
    
    ; Reset all winner flags
    mov byte [winner_flags], 0
    
    ; Check each player against the max
    mov ax, [player1_laps]
    cmp ax, [max_laps]
    jne .check_p2
    or byte [winner_flags], 1  ; Set P1 flag
    
.check_p2:
    mov ax, [player2_laps]
    cmp ax, [max_laps]
    jne .check_b1
    or byte [winner_flags], 2  ; Set P2 flag
    
.check_b1:
    mov ax, [bot1_laps]
    cmp ax, [max_laps]
    jne .check_b2
    or byte [winner_flags], 4  ; Set B1 flag
    
.check_b2:
    mov ax, [bot2_laps]
    cmp ax, [max_laps]
    jne .check_b3
    or byte [winner_flags], 8  ; Set B2 flag
    
.check_b3:
    mov ax, [bot3_laps]
    cmp ax, [max_laps]
    jne .done
    or byte [winner_flags], 16 ; Set B3 flag
    
.done:
    popa
    ret

show_winner_message:
    pusha

    ; Mensaje fijo: "Ganador(es):"
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 0x0E  ; color
    mov dh, 5      ; Fila 5 (modo texto)
    mov dl, 33     ; Columna centrada
    mov cx, 12
    mov bp, victory_str
    int 0x10

    ; Variables para posiciones
    mov byte [current_row], 7  ; Fila inicial para los ganadores

    ; Verificar cada bandera
    test byte [winner_flags], 1
    jz .check_p2
    call print_p1
    inc byte [current_row]

.check_p2:
    test byte [winner_flags], 2
    jz .check_b1
    call print_p2
    inc byte [current_row]

.check_b1:
    test byte [winner_flags], 4
    jz .check_b2
    call print_b1
    inc byte [current_row]

.check_b2:
    test byte [winner_flags], 8
    jz .check_b3
    call print_b2
    inc byte [current_row]

.check_b3:
    test byte [winner_flags], 16
    jz .done
    call print_b3

.done:
    popa
    ret

; Subrutinas de impresión actualizadas
print_p1:
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 0x0A
    mov dh, [current_row]
    mov dl, 33
    mov cx, 14
    mov bp, p1_win_str
    int 0x10
    ret

print_p2:
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 0x0C
    mov dh, [current_row]
    mov dl, 33
    mov cx, 14
    mov bp, p2_win_str
    int 0x10
    ret

print_b1:
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 0x01
    mov dh, [current_row]
    mov dl, 33
    mov cx, 10
    mov bp, b1_win_str
    int 0x10
    ret

print_b2:
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 0x0E
    mov dh, [current_row]
    mov dl, 33
    mov cx, 10
    mov bp, b2_win_str
    int 0x10
    ret

print_b3:
    mov ah, 0x13
    mov al, 0x01
    mov bh, 0
    mov bl, 0x05
    mov dh, [current_row]
    mov dl, 33
    mov cx, 10
    mov bp, b3_win_str
    int 0x10
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


; Bot 2
bot2_x          dw 80    ; Posición inicial en X
bot2_y          dw 50     ; Posición inicial en Y (un poco más abajo que el primer bot)
bot2_color      db 14      ; Marrón
bot2_width      dw 10     
bot2_height     dw 10     
old_bot2_x      dw 100
old_bot2_y      dw 70
bot2_direction  db 1      ; Dirección inicial: derecha

; Bot 3
bot3_x          dw 80    ; Posición inicial en X
bot3_y          dw 30     ; Posición inicial en Y (un poco más abajo que el segundo bot)
bot3_color      db 5      ; Magenta
bot3_width      dw 10     
bot3_height     dw 10     
old_bot3_x      dw 100
old_bot3_y      dw 85
bot3_direction  db 1      ; Dirección inicial: derecha

; Para la rutina de colisión
x_off           dw 0
y_off           dw 0

; Temporizador
time_start      dw 0      ; Ticks iniciales (BIOS)
time_current    dw 0      ; Ticks actuales
time_seconds    dw 60     ; Segundos restantes
time_str        db 'Time: 60', 0

; Puntos de cambio de dirección para el bot
waypoint_range dw 20      ; Rango de tolerancia en píxeles

waypoint1_x    dw 600    ; Primer punto X
waypoint1_y    dw 40     ; Primer punto Y
waypoint1_dir  db 2      ; Nueva dirección (2=Abajo)

waypoint2_x    dw 600    ; Segundo punto X
waypoint2_y    dw 250    ; Segundo punto Y
waypoint2_dir  db 3      ; Nueva dirección (3=Izquierda)

waypoint3_x    dw 30    ; Tercer punto X
waypoint3_y    dw 250    ; Tercer punto Y
waypoint3_dir  db 4      ; Nueva dirección (4=Arriba)

waypoint4_x    dw 30    ; Cuarto punto X
waypoint4_y    dw 40     ; Cuarto punto Y
waypoint4_dir  db 1      ; Nueva dirección (1=Derecha)

; Variables para velocidades de los bots
bot_speed       dw 5      ; Velocidad inicial (será reemplazada por valor aleatorio)
bot2_speed      dw 5      ; Velocidad inicial (será reemplazada por valor aleatorio)
bot3_speed      dw 5      ; Velocidad inicial (será reemplazada por valor aleatorio)
random_seed     dw 0      ; Semilla para generación de números aleatorios


; Variable temporal para cálculos
random_range_temp dw 0


; Contadores de vueltas
player1_laps     dw 0      ; Vueltas del jugador 1
player1_lap_str  db 'P1 Laps: 00', 0  ; Cadena para mostrar
checkpoint_x1    dw 10    ; X mínima del punto de control
checkpoint_x2    dw 100    ; X máxima del punto de control
checkpoint_y1    dw 10     ; Y mínima del punto de control
checkpoint_y2    dw 130     ; Y máxima del punto de control
in_checkpoint    db 0      ; Flag para indicar si ya está en el checkpoint

checkpoint2_x1    dw 550    ; X min of the second checkpoint
checkpoint2_x2    dw 600    ; X max of the second checkpoint
checkpoint2_y1    dw 200    ; Y min of the second checkpoint
checkpoint2_y2    dw 300    ; Y max of the second checkpoint
checkpoint2_passed db 0     ; Flag to indicate if checkpoint2 has been passed

player2_laps     dw 0      ; Vueltas del jugador 2
player2_lap_str  db 'P2 Laps: 00', 0  ; Cadena para mostrar
checkpoint2_passed_p2 db 0     ; Flag para Player 2
in_checkpoint_p2    db 0      ; Flag para indicar si está en el checkpoint


; Bot 1
bot1_laps       dw 0      ; Vueltas del bot 1
bot1_lap_str    db 'P3 Laps: 00', 0
checkpoint2_passed_bot1 db 0
in_checkpoint_bot1 db 0

; Bot 2
bot2_laps       dw 0      ; Vueltas del bot 2
bot2_lap_str    db 'P4 Laps: 00', 0
checkpoint2_passed_bot2 db 0
in_checkpoint_bot2 db 0

; Bot 3
bot3_laps       dw 0      ; Vueltas del bot 3
bot3_lap_str    db 'P5 Laps: 00', 0
checkpoint2_passed_bot3 db 0
in_checkpoint_bot3 db 0


victory_str db 'Ganador(es):', 0
p1_win_str     db 'Jugador 1 (P1)', 0
p2_win_str     db 'Jugador 2 (P2)', 0
b1_win_str     db 'Bot 1 (P3)', 0
b2_win_str     db 'Bot 2 (P4)', 0
b3_win_str     db 'Bot 3 (P5)', 0

max_laps       dw 0
winner_flags   db 0

current_row db 7  ; Fila actual para imprimir ganadores

; Observa que aquí ya no utilizamos "TIMES 510 - ($-$$) db 0" ni "dw 0xAA55"
; porque esto NO es un boot sector.
