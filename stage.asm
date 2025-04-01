; =============================================================================
; SEGUNDA ETAPA (STAGE 2) - JUEGO DE CARRERAS
; =============================================================================
; Este código implementa un juego de carreras con 2 jugadores humanos y 3 bots
; controlados por la computadora. Se carga en la dirección 0x1000:0 por el
; bootloader (primera etapa).
; =============================================================================
[bits 16]       ; Indicamos que usamos modo real de 16 bits
[org 0x0000]    ; Código se cargará en el offset 0 del segmento 0x1000

; =============================================================================
; INICIALIZACIÓN DEL JUEGO
; =============================================================================
; Stage 2 se carga en 0x1000:0 por boot1.
; Al saltar aquí, CS=0x1000 (normalmente), DS=0, ES=0
; =============================================================================
inicio:
    ; Configurar segmento de datos para acceso a variables
    mov ax, 0x1000
    mov ds, ax ; DS = 0x1000 para acceder a variables

    ; Iniciar modo gráfico 640x480, 16 colores (modo VGA 12h)
    mov ax, 0x12
    int 0x10

    ; =============================================================================
    ; INICIALIZACIÓN DEL SISTEMA ALEATORIO Y VELOCIDADES
    ; =============================================================================
    ; Inicializar sistema aleatorio basado en ticks del sistema
    call init_random_seed

    ; Asignar velocidades aleatorias a bots (5-20)
    mov bx, 5   ; Valor mínimo de velocidad
    mov cx, 15  ; Valor máximo de velocidad
    call random_range ; Genera número aleatorio entre 5-15
    mov [bot_speed], ax ; Guarda velocidad para Bot1

    mov bx, 5
    mov cx, 15
    call random_range ; Velocidad Bot2
    mov [bot2_speed], ax

    mov bx, 5
    mov cx, 15
    call random_range ; Velocidad Bot3
    mov [bot3_speed], ax
    
    ; =============================================================================
    ; CONFIGURACIÓN DEL TEMPORIZADOR
    ; =============================================================================
    ; Obtener tiempo inicial del sistema
    mov ah, 0x00
    int 0x1A        ; Interrupción BIOS para hora del sistema
    mov [time_start], dx  ; Guarda tiempo inicial (ticks)
    
    ; =============================================================================
    ; DIBUJO INICIAL DE ELEMENTOS
    ; =============================================================================
    ; Dibujar pista y elementos de la UI
    call draw_track ; Dibuja pista en color blanco
    call update_timer  ; Muestra el temporizador en pantalla
    call update_lap_counter  ; Muestra contador de vueltas

    ; Verificar si algún jugador ha completado vueltas (inicialmente 0)
    call check_player1_lap
    
    call check_player2_lap
    call update_lap_counter_p2

    call check_bot1_lap
    call update_lap_counter_bot1

    call check_bot2_lap
    call update_lap_counter_bot2

    call check_bot3_lap
    call update_lap_counter_bot3

    ; =============================================================================
    ; DIBUJADO INICIAL DE JUGADORES Y BOTS
    ; =============================================================================
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

    ; ---- BOT 1 (AZUL) ----
    mov al, [bot_color]
    mov cx, [bot_x]
    mov dx, [bot_y]
    mov si, [bot_width]
    mov di, [bot_height]
    call draw_rectangle

    ; ---- BOT 2 (AMARILLO) ----
    mov al, [bot2_color]
    mov cx, [bot2_x]
    mov dx, [bot2_y]
    mov si, [bot2_width]
    mov di, [bot2_height]
    call draw_rectangle

    ; ---- BOT 3 (MORADO) ----
    mov al, [bot3_color]
    mov cx, [bot3_x]
    mov dx, [bot3_y]
    mov si, [bot3_width]
    mov di, [bot3_height]
    call draw_rectangle

; =============================================================================
; BUCLE PRINCIPAL DEL JUEGO
; =============================================================================
main_loop:
    ; 1) Guardar las posiciones actuales para borrar luego
    mov ax, [player_x]
    mov [old_x], ax         ; Guarda posición X del jugador 1
    mov ax, [player_y]
    mov [old_y], ax         ; Guarda posición Y del jugador 1

    mov ax, [player2_x]
    mov [old2_x], ax        ; Guarda posición X del jugador 2
    mov ax, [player2_y]
    mov [old2_y], ax        ; Guarda posición Y del jugador 2

    ; 2) Leer entrada de teclado
    call read_key           ; Obtiene tecla presionada (AH=scancode, AL=ASCII)

    ; 3) Actualizar posiciones de los jugadores según tecla
    call update_position    ; Mueve jugadores según tecla presionada

    ; 3b) Comprobar colisiones con la pista
    call check_collision_player1  ; Verifica colisión del jugador 1
    call check_collision_player2  ; Verifica colisión del jugador 2

    ; 4) Borrar los rectángulos de posiciones anteriores
    ; -- Jugador 1 --
    mov al, 0               ; Color 0 = negro (borra)
    mov cx, [old_x]         ; Posición X antigua
    mov dx, [old_y]         ; Posición Y antigua
    mov si, [player_width]  ; Mismo ancho
    mov di, [player_height] ; Mismo alto
    call draw_rectangle     ; Borra dibujando rectángulo negro

    ; -- Jugador 2 --
    mov al, 0               ; Color 0 = negro (borra)
    mov cx, [old2_x]        ; Posición X antigua
    mov dx, [old2_y]        ; Posición Y antigua
    mov si, [player2_width] ; Mismo ancho
    mov di, [player2_height]; Mismo alto
    call draw_rectangle     ; Borra dibujando rectángulo negro

    ; 5) Dibujar jugadores en las nuevas posiciones
    ; -- Jugador 1 --
    mov al, [player_color]  ; Color original
    mov cx, [player_x]      ; Nueva posición X
    mov dx, [player_y]      ; Nueva posición Y
    mov si, [player_width]  ; Ancho
    mov di, [player_height] ; Alto
    call draw_rectangle     ; Dibuja en nueva posición

    ; -- Jugador 2 --
    mov al, [player2_color] ; Color original
    mov cx, [player2_x]     ; Nueva posición X
    mov dx, [player2_y]     ; Nueva posición Y
    mov si, [player2_width] ; Ancho
    mov di, [player2_height]; Alto
    call draw_rectangle     ; Dibuja en nueva posición

    ; =============================================================================
    ; ACTUALIZACIÓN DE BOT 1
    ; =============================================================================
    ; 1) Guardar posición anterior
    mov ax, [bot_x]
    mov [old_bot_x], ax     ; Guarda posición X antigua
    mov ax, [bot_y]
    mov [old_bot_y], ax     ; Guarda posición Y antigua

    ; 2) Mover bot según su lógica interna
    call move_bot           ; Actualiza posición del bot 1

    ; 3) Borrar bot de posición anterior
    mov al, 0               ; Color 0 = negro (borra)
    mov cx, [old_bot_x]     ; Posición X antigua
    mov dx, [old_bot_y]     ; Posición Y antigua
    mov si, [bot_width]     ; Ancho
    mov di, [bot_height]    ; Alto
    call draw_rectangle     ; Borra dibujando rectángulo negro

    ; 4) Dibujar bot en nueva posición
    mov al, [bot_color]     ; Color original
    mov cx, [bot_x]         ; Nueva posición X
    mov dx, [bot_y]         ; Nueva posición Y
    mov si, [bot_width]     ; Ancho
    mov di, [bot_height]    ; Alto
    call draw_rectangle     ; Dibuja en nueva posición

    ; =============================================================================
    ; ACTUALIZACIÓN DE BOT 2
    ; =============================================================================
    ; 1) Guardar posición anterior
    mov ax, [bot2_x]
    mov [old_bot2_x], ax    ; Guarda posición X antigua
    mov ax, [bot2_y]
    mov [old_bot2_y], ax    ; Guarda posición Y antigua

    ; 2) Mover bot 2
    call move_bot2          ; Actualiza posición del bot 2

    ; 3) Borrar bot de posición anterior
    mov al, 0               ; Color 0 = negro (borra)
    mov cx, [old_bot2_x]    ; Posición X antigua
    mov dx, [old_bot2_y]    ; Posición Y antigua
    mov si, [bot2_width]    ; Ancho
    mov di, [bot2_height]   ; Alto
    call draw_rectangle     ; Borra dibujando rectángulo negro

    ; 4) Dibujar bot en nueva posición
    mov al, [bot2_color]    ; Color original
    mov cx, [bot2_x]        ; Nueva posición X
    mov dx, [bot2_y]        ; Nueva posición Y
    mov si, [bot2_width]    ; Ancho
    mov di, [bot2_height]   ; Alto
    call draw_rectangle     ; Dibuja en nueva posición

    ; =============================================================================
    ; ACTUALIZACIÓN DE BOT 3
    ; =============================================================================
    ; 1) Guardar posición anterior
    mov ax, [bot3_x]
    mov [old_bot3_x], ax    ; Guarda posición X antigua
    mov ax, [bot3_y]
    mov [old_bot3_y], ax    ; Guarda posición Y antigua

    ; 2) Mover bot 3
    call move_bot3          ; Actualiza posición del bot 3

    ; 3) Borrar bot de posición anterior
    mov al, 0               ; Color 0 = negro (borra)
    mov cx, [old_bot3_x]    ; Posición X antigua
    mov dx, [old_bot3_y]    ; Posición Y antigua
    mov si, [bot3_width]    ; Ancho
    mov di, [bot3_height]   ; Alto
    call draw_rectangle     ; Borra dibujando rectángulo negro

    ; 4) Dibujar bot en nueva posición
    mov al, [bot3_color]    ; Color original
    mov cx, [bot3_x]        ; Nueva posición X
    mov dx, [bot3_y]        ; Nueva posición Y
    mov si, [bot3_width]    ; Ancho
    mov di, [bot3_height]   ; Alto
    call draw_rectangle     ; Dibuja en nueva posición

    ; =============================================================================
    ; VERIFICACIÓN DE VUELTAS
    ; =============================================================================
    ; Comprobar vueltas para todos los participantes
    call check_player1_lap
    call update_lap_counter
    call check_player2_lap
    call update_lap_counter_p2

    call check_bot1_lap
    call update_lap_counter_bot1

    call check_bot2_lap
    call update_lap_counter_bot2

    call check_bot3_lap
    call update_lap_counter_bot3

    ; 6) Actualizar temporizador del juego
    call update_timer       ; Actualiza y muestra el tiempo restante

    ; Volver al inicio del bucle principal
    jmp main_loop


; =============================================================================
; SUBRUTINA: LEER TECLA
; =============================================================================
; Espera a que se presione una tecla y devuelve su scancode en AH
; y el código ASCII en AL.
; =============================================================================
read_key:
    mov ah, 0x00           ; Función 0 de INT 16h (leer tecla)
    int 0x16               ; Interrupción de teclado BIOS
    ret

; =============================================================================
; SUBRUTINA: ACTUALIZAR POSICIÓN
; =============================================================================
; Maneja entrada de teclado para mover a los jugadores
; - Jugador 1: usa flechas para moverse (↑,↓,←,→)
; - Jugador 2: usa teclas WASD (W=arriba, S=abajo, A=izquierda, D=derecha)
; Incluye límites para evitar que salgan de la pantalla
; =============================================================================

update_position:
    ; Analiza qué tecla se presionó usando el scancode en AH

    ; Jugador 1: flechas
    cmp ah, 0x48           ; Flecha ↑ (scancode 0x48)
    je move_up_1
    cmp ah, 0x50           ; Flecha ↓ (scancode 0x50)
    je move_down_1
    cmp ah, 0x4B           ; Flecha ← (scancode 0x4B)
    je move_left_1
    cmp ah, 0x4D           ; Flecha → (scancode 0x4D)
    je move_right_1

    ; Jugador 2: W, S, A, D
    cmp ah, 0x11           ; W (scancode 0x11)
    je move_up_2
    cmp ah, 0x1F           ; S (scancode 0x1F)
    je move_down_2
    cmp ah, 0x1E           ; A (scancode 0x1E)
    je move_left_2
    cmp ah, 0x20           ; D (scancode 0x20)
    je move_right_2

    ret

; --- Rutinas de movimiento para Jugador 1 (verde) ---
; Cada rutina valida que no se salga de los límites (0..639, 0..479)
move_up_1:
    cmp word [player_y], 1     ; Verifica límite superior
    jle done                   ; Si ya está en el límite, no hace nada
    sub word [player_y], 10    ; Mueve 10 píxeles hacia arriba
    jmp done

move_down_1:
    cmp word [player_y], 470   ; Verifica límite inferior (479-alto del jugador)
    jge done                   ; Si ya está en el límite, no hace nada
    add word [player_y], 10    ; Mueve 10 píxeles hacia abajo
    jmp done

move_left_1:
    cmp word [player_x], 1     ; Verifica límite izquierdo
    jle done                   ; Si ya está en el límite, no hace nada
    sub word [player_x], 10    ; Mueve 10 píxeles a la izquierda
    jmp done

move_right_1:
    cmp word [player_x], 630   ; Verifica límite derecho (639-ancho del jugador)
    jge done                   ; Si ya está en el límite, no hace nada
    add word [player_x], 10    ; Mueve 10 píxeles a la derecha
    jmp done

; --- Rutinas de movimiento para Jugador 2 (rojo) ---
; Similar al jugador 1 pero controla al segundo jugador
move_up_2:
    cmp word [player2_y], 1    ; Verifica límite superior
    jle done                   ; Si ya está en el límite, no hace nada
    sub word [player2_y], 10   ; Mueve 10 píxeles hacia arriba
    jmp done

move_down_2:
    cmp word [player2_y], 470  ; Verifica límite inferior
    jge done                   ; Si ya está en el límite, no hace nada
    add word [player2_y], 10   ; Mueve 10 píxeles hacia abajo
    jmp done

move_left_2:
    cmp word [player2_x], 1    ; Verifica límite izquierdo
    jle done                   ; Si ya está en el límite, no hace nada
    sub word [player2_x], 10   ; Mueve 10 píxeles a la izquierda
    jmp done

move_right_2:
    cmp word [player2_x], 630  ; Verifica límite derecho
    jge done                   ; Si ya está en el límite, no hace nada
    add word [player2_x], 10   ; Mueve 10 píxeles a la derecha
    jmp done

done:
    ret

; =============================================================================
; SUBRUTINA: MOVER EL BOT 1
; =============================================================================
; Controla el movimiento del Bot 1 según su dirección actual y velocidad
; La dirección se ajusta en los "waypoints" (puntos de cambio)
; =============================================================================
move_bot:
    ; Primero comprobar si ha llegado a un punto de cambio de dirección
    call check_bot_waypoints
    
    ; Realizar el movimiento según la dirección actual
    cmp byte [bot_direction], 1  ; ¿Dirección derecha?
    je bot_move_right
    cmp byte [bot_direction], 2  ; ¿Dirección abajo?
    je bot_move_down
    cmp byte [bot_direction], 3  ; ¿Dirección izquierda?
    je bot_move_left
    cmp byte [bot_direction], 4  ; ¿Dirección arriba?
    je bot_move_up
    ret

; --- Rutinas de movimiento según dirección ---
bot_move_right:
    mov cx, [bot_speed]      ; Usar velocidad del bot para el desplazamiento
    add word [bot_x], cx     ; Mover bot hacia la derecha
    ret

bot_move_down:
    mov cx, [bot_speed]      ; Usar velocidad del bot
    add word [bot_y], cx     ; Mover bot hacia abajo
    ret

bot_move_left:
    mov cx, [bot_speed]      ; Usar velocidad del bot
    sub word [bot_x], cx     ; Mover bot hacia la izquierda
    ret

bot_move_up:
    mov cx, [bot_speed]      ; Usar velocidad del bot
    sub word [bot_y], cx     ; Mover bot hacia arriba
    ret

; =============================================================================
; SUBRUTINA: MOVER EL BOT 2
; =============================================================================
; Controla el movimiento del Bot 2 de manera similar al Bot 1
; =============================================================================
move_bot2:
    ; Comprobar si ha llegado a un punto de cambio
    call check_bot2_waypoints
    
    ; Comprobar si ha llegado a un punto de cambio de dirección
    call check_bot2_waypoints
    
    ; Realizar el movimiento según la dirección actual
    cmp byte [bot2_direction], 1  ; ¿Dirección derecha?
    je bot2_move_right
    cmp byte [bot2_direction], 2  ; ¿Dirección abajo?
    je bot2_move_down
    cmp byte [bot2_direction], 3  ; ¿Dirección izquierda?
    je bot2_move_left
    cmp byte [bot2_direction], 4  ; ¿Dirección arriba?
    je bot2_move_up
    ret

; --- Rutinas de movimiento del Bot 2 ---
bot2_move_right:
    mov cx, [bot2_speed]     ; Usar velocidad del bot 2
    add word [bot2_x], cx    ; Mover hacia la derecha
    ret

bot2_move_down:
    mov cx, [bot2_speed]     ; Usar velocidad del bot 2
    add word [bot2_y], cx    ; Mover hacia abajo
    ret

bot2_move_left:
    mov cx, [bot2_speed]     ; Usar velocidad del bot 2
    sub word [bot2_x], cx    ; Mover hacia la izquierda
    ret

bot2_move_up:
    mov cx, [bot2_speed]     ; Usar velocidad del bot 2
    sub word [bot2_y], cx    ; Mover hacia arriba
    ret
    
; =============================================================================
; SUBRUTINA: MOVER EL BOT 3
; =============================================================================
; Controla el movimiento del Bot 3 de manera similar a los otros bots
; =============================================================================
move_bot3:
    ; Comprobar si ha llegado a un punto de cambio
    call check_bot3_waypoints
    
    ; Comprobar si ha llegado a un punto de cambio
    call check_bot3_waypoints
    
    ; Realizar el movimiento según la dirección actual
    cmp byte [bot3_direction], 1  ; ¿Dirección derecha?
    je bot3_move_right
    cmp byte [bot3_direction], 2  ; ¿Dirección abajo?
    je bot3_move_down
    cmp byte [bot3_direction], 3  ; ¿Dirección izquierda?
    je bot3_move_left
    cmp byte [bot3_direction], 4  ; ¿Dirección arriba?
    je bot3_move_up
    ret

; --- Rutinas de movimiento del Bot 3 ---
bot3_move_right:
    mov cx, [bot3_speed]     ; Usar velocidad del bot 3
    add word [bot3_x], cx    ; Mover hacia la derecha
    ret

bot3_move_down:
    mov cx, [bot3_speed]     ; Usar velocidad del bot 3
    add word [bot3_y], cx    ; Mover hacia abajo
    ret

bot3_move_left:
    mov cx, [bot3_speed]     ; Usar velocidad del bot 3
    sub word [bot3_x], cx    ; Mover hacia la izquierda
    ret

bot3_move_up:
    mov cx, [bot3_speed]     ; Usar velocidad del bot 3
    sub word [bot3_y], cx    ; Mover hacia arriba
    ret


; =============================================================================
; SUBRUTINA: VERIFICAR PUNTOS DE CAMBIO DEL BOT 1
; =============================================================================
; Comprueba si el Bot 1 ha llegado a alguno de los 4 waypoints donde
; debe cambiar de dirección. Usa un sistema de detección por cercanía.
; =============================================================================
check_bot_waypoints:
    ; Comprueba si el bot ha llegado al punto de cambio 1 (USANDO RANGOS)
    ; 1) Calcular distancia en X al waypoint1
    mov ax, [bot_x]
    sub ax, [waypoint1_x]     ; AX = bot_x - waypoint1_x
    jns check_wp1_positive    ; Si es positivo, seguir
    neg ax                    ; Si es negativo, hacerlo positivo
check_wp1_positive:
    cmp ax, [waypoint_range]  ; Comparar con el rango aceptable
    ja check_waypoint2        ; Si está fuera del rango, comprobar el siguiente waypoint
    
    ; 2) Calcular distancia en Y al waypoint1
    mov ax, [bot_y]
    sub ax, [waypoint1_y]
    jns check_wp1_y_positive
    neg ax
check_wp1_y_positive:
    cmp ax, [waypoint_range]
    ja check_waypoint2
    
    ; Si llegó aquí, el bot está en el rango del waypoint1
    mov al, [waypoint1_dir]    ; Cargar nueva dirección
    mov [bot_direction], al    ; Aplicar cambio de dirección
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

; =============================================================================
; SUBRUTINA: VERIFICAR PUNTOS DE CAMBIO DEL BOT 2
; =============================================================================
; Similar a la función para el Bot 1, pero para el Bot 2
; =============================================================================
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

; =============================================================================
; SUBRUTINA: VERIFICAR PUNTOS DE CAMBIO DEL BOT 3
; =============================================================================
; Similar a las anteriores, verifica si el Bot 3 ha llegado a los waypoints
; para cambiar su dirección
; =============================================================================
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

; =============================================================================
; SUBRUTINA: DIBUJAR RECTÁNGULO
; =============================================================================
; Dibuja un rectángulo con el color y dimensiones especificados
; Entrada:
;   - AL = color del rectángulo (0-15 en modo VGA)
;   - CX = coordenada X (esquina superior izquierda)
;   - DX = coordenada Y (esquina superior izquierda)
;   - SI = ancho del rectángulo en píxeles
;   - DI = alto del rectángulo en píxeles
; =============================================================================
draw_rectangle:
    ; Preservar registros que usa la función
    push cx
    push dx
    push si
    mov bx, di  ; guardamos alto en bx (liberamos DI)

.filas:
    mov si, [esp]       ; ancho en SI (cada vuelta se reinicia)
    mov cx, [esp+4]     ; X inicial (desde la pila)

.columnas:
    mov ah, 0x0C        ; Función BIOS: Escribir píxel
    xor bh, bh          ; Página 0 de video
    int 0x10            ; Interrupción gráfica BIOS

    inc cx              ; Siguiente píxel en X
    dec si              ; Decrementar contador de ancho
    jnz .columnas       ; Continuar si no se ha dibujado toda la fila

    inc dx              ; Siguiente fila (Y)
    dec bx              ; Decrementar contador de alto
    jnz .filas          ; Continuar si no se han dibujado todas las filas

    ; Restaurar registros
    pop si
    pop dx
    pop cx
    ret

; =============================================================================
; SUBRUTINA: ACTUALIZAR TEMPORIZADOR
; =============================================================================
; Muestra el tiempo restante de juego en la pantalla
; El juego termina cuando el tiempo llega a cero
; =============================================================================
update_timer:
    pusha               ; Preservar todos los registros
    
    ; Obtener ticks actuales del reloj del sistema
    mov ah, 0x00        ; Función 0 de INT 1Ah: Obtener ticks
    int 0x1A            ; Interrupción BIOS de reloj
    mov [time_current], dx

    ; Calcular segundos transcurridos (18.2 ticks/segundo en BIOS)
    mov ax, [time_current]
    sub ax, [time_start]    ; AX = ticks transcurridos
    xor dx, dx              ; Limpiar DX para división
    mov cx, 18              ; Aproximadamente 18.2 ticks/segundo
    div cx                  ; AX = segundos aproximados

    ; Calcular segundos restantes (partida de 60 segundos)
    mov bx, 60              ; Tiempo inicial: 60 segundos
    sub bx, ax              ; BX = segundos restantes
    mov [time_seconds], bx

    ; Verificar si se acabó el tiempo
    cmp word [time_seconds], 0
    jne .continue_game      ; Si aún hay tiempo, continuar
    jmp game_over           ; Si tiempo = 0, fin del juego

    .continue_game:
    ; Actualizar cadena del tiempo para mostrar en pantalla
    mov di, time_str + 6    ; Posición del número en "Time: 60"
    mov ax, [time_seconds]
    call word_to_ascii      ; Convertir valor a ASCII

    ; Dibujar el tiempo en pantalla
    mov ah, 0x13            ; Función BIOS: Escribir cadena
    mov al, 0x01            ; Modo de escritura (actualizar posición)
    mov bh, 0x00            ; Página 0
    mov bl, 0x0F            ; Color blanco sobre negro
    mov cx, 8               ; Longitud de la cadena
    mov dh, 17              ; Fila 17
    mov dl, 3               ; Columna 3
    mov bp, time_str        ; Dirección de la cadena
    int 0x10                ; Interrupción de video BIOS

    popa                    ; Restaurar registros
    ret

; =============================================================================
; SUBRUTINA: GAME OVER
; =============================================================================
; Maneja el fin del juego cuando el tiempo llega a cero
; Cambia a modo texto, determina el ganador y muestra el resultado
; =============================================================================
game_over:
    ; Cambiar a modo texto 80x25 (16 colores)
    mov ax, 0x0003          ; Modo texto estándar
    int 0x10                ; Cambiar modo de video
    
    call determine_winner   ; Determinar ganador(es)
    call show_winner_message ; Mostrar mensaje con el ganador
.halt:
    jmp .halt               ; Bucle infinito para congelar el juego

; =============================================================================
; SUBRUTINA: CONVERTIR WORD A ASCII
; =============================================================================
; Convierte un valor numérico en cadena ASCII
; Entrada: 
;   - AX = número a convertir
;   - DI = dirección de destino para guardar
; =============================================================================
word_to_ascii:
    pusha
    mov cx, 10              ; Divisor (base 10)
    xor dx, dx              ; Limpiar DX para división
    div cx                  ; AX = cociente, DX = residuo
    add dl, '0'             ; Convertir residuo a ASCII
    mov [di+1], dl          ; Guardar segundo dígito
    xor dx, dx              ; Limpiar DX para división
    div cx                  ; División nuevamente para primer dígito
    add dl, '0'             ; Convertir a ASCII
    mov [di], dl            ; Guardar primer dígito
    popa                    ; Restaurar registros
    ret

; =============================================================================
; SUBRUTINA: DIBUJAR LA PISTA
; =============================================================================
; Dibuja la pista de carreras con rectángulos blancos
; La pista define los límites del circuito
; =============================================================================
draw_track:
    ; Parámetros para dibujar:
    ; AL: Color del rectángulo (15 = blanco)
    ; CX: Coordenada X de la esquina superior izquierda
    ; DX: Coordenada Y de la esquina superior izquierda
    ; SI: Ancho del rectángulo
    ; DI: Alto del rectángulo

    ; Tramo 1.1 - Borde superior horizontal
    mov al, 15              ; Color blanco
    mov cx, 20              ; X inicial
    mov dx, 15              ; Y inicial
    mov si, 600             ; Ancho
    mov di, 5               ; Alto
    call draw_rectangle

    ; Tramo 1.2 - Borde superior interno horizontal
    mov al, 15
    mov cx, 80
    mov dx, 75
    mov si, 480
    mov di, 5
    call draw_rectangle

    ; Tramo 2.1 - Borde derecho externo vertical
    mov al, 15
    mov cx, 620
    mov dx, 15
    mov si, 5
    mov di, 250
    call draw_rectangle

    ; Tramo 2.2 - Borde derecho interno vertical
    mov al, 15
    mov cx, 555
    mov dx, 80
    mov si, 5
    mov di, 125
    call draw_rectangle

    ; Tramo 3.1 - Borde inferior externo horizontal
    mov al, 15
    mov cx, 25
    mov dx, 265
    mov si, 600
    mov di, 5
    call draw_rectangle

    ; Tramo 3.2 - Borde inferior interno horizontal
    mov al, 15
    mov cx, 80
    mov dx, 200
    mov si, 480
    mov di, 5
    call draw_rectangle

    ; Tramo 4.1 - Borde izquierdo externo vertical
    mov al, 15
    mov cx, 20
    mov dx, 15
    mov si, 5
    mov di, 255
    call draw_rectangle

    ; Tramo 4.2 - Borde izquierdo interno vertical
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
