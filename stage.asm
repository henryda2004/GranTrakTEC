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
    ; Inicializar temporizador (obtener ticks iniciales)
    mov ah, 0x00
    int 0x1A
    mov [time_start], dx  ; Guardar ticks iniciales (CX:DX)
    
    ; Dibujar elementos iniciales
    call draw_track
    call update_timer  ; Mostrar tiempo inicial


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
    mov dh, 0           ; Fila 0
    mov dl, 0           ; Columna 0
    mov bp, time_str
    int 0x10

    popa
    ret

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

; Temporizador
time_start      dw 0      ; Ticks iniciales (BIOS)
time_current    dw 0      ; Ticks actuales
time_seconds    dw 60     ; Segundos restantes
time_str        db 'Time: 60', 0

; Puntos de cambio de dirección para el bot
waypoint_range dw 5      ; Rango de tolerancia en píxeles

waypoint1_x    dw 580    ; Primer punto X
waypoint1_y    dw 55     ; Primer punto Y
waypoint1_dir  db 2      ; Nueva dirección (2=Abajo)

waypoint2_x    dw 580    ; Segundo punto X
waypoint2_y    dw 250    ; Segundo punto Y
waypoint2_dir  db 3      ; Nueva dirección (3=Izquierda)

waypoint3_x    dw 30    ; Tercer punto X
waypoint3_y    dw 250    ; Tercer punto Y
waypoint3_dir  db 4      ; Nueva dirección (4=Arriba)

waypoint4_x    dw 30    ; Cuarto punto X
waypoint4_y    dw 55     ; Cuarto punto Y
waypoint4_dir  db 1      ; Nueva dirección (1=Derecha)
; Observa que aquí ya no utilizamos "TIMES 510 - ($-$$) db 0" ni "dw 0xAA55"
; porque esto NO es un boot sector.