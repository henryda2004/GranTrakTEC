BITS 16
ORG 0x7C00   ; Código de arranque

; ======= CAMBIAR A MODO GRÁFICO 13h =======
mov ax, 0x13
int 0x10 

; ======= DIBUJAR UN CUADRADO AZUL (CARRO) =======
mov cx, 50  ; X inicial del cuadrado
ciclo_x:
    mov dx, 50  ; Y inicial del cuadrado
ciclo_y:
    mov ah, 0x0C
    mov al, 1  ; Color azul
    int 0x10  
    inc dx
    cmp dx, 60  ; Altura del cuadrado (10 px)
    jl ciclo_y
inc cx
cmp cx, 60  ; Ancho del cuadrado (10 px)
jl ciclo_x

; ======= BUCLE INFINITO PARA MANTENER LA PANTALLA =======
jmp $

; ======= RELLENAR HASTA 510 BYTES Y FIRMA DE ARRANQUE =======
times 510-($-$$) db 0
dw 0xAA55
